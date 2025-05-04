import os

from torch import nn
import torch
import torchvision
import torchvision.transforms as transforms
from torchvision.datasets import CIFAR10
from torch.utils.data import DataLoader

import onnx
from onnx2pytorch import ConvertModel

import brevitas.nn as qnn
import brevitas.onnx as bo
from brevitas.core.quant import QuantType
import torch.nn.functional as F

from brevitas.quant import Int8WeightPerTensorFixedPoint, Int8ActPerTensorFixedPoint, Int8BiasPerTensorFloatInternalScaling, Int8BiasPerTensorFixedPointInternalScaling

import numpy as np

import argparse
import time

class QuantAlexNet(nn.Module):
    
    def __init__(self):
        super(QuantAlexNet, self).__init__()
        self.features = nn.Sequential(
            qnn.QuantIdentity(act_quant=Int8ActPerTensorFixedPoint, bit_width=8, return_quant_tensor=True),
            qnn.QuantConv2d(3, 96, 11, 4, weight_quant=Int8WeightPerTensorFixedPoint, bias=False, weight_bit_width=8),
            qnn.QuantReLU(act_quant=Int8ActPerTensorFixedPoint, bit_width=8, return_quant_tensor=True),
            nn.MaxPool2d(3, 2),
            qnn.QuantConv2d(96, 256, 5, 1, 2, weight_quant=Int8WeightPerTensorFixedPoint, bias=False, weight_bit_width=8),
            qnn.QuantReLU(act_quant=Int8ActPerTensorFixedPoint, bit_width=8, return_quant_tensor=True),
            nn.MaxPool2d(3, 2),
            qnn.QuantConv2d(256, 384, 3, 1, 1, weight_quant=Int8WeightPerTensorFixedPoint, bias=False, weight_bit_width=8),
            qnn.QuantReLU(act_quant=Int8ActPerTensorFixedPoint, bit_width=8, return_quant_tensor=True),
            qnn.QuantConv2d(384, 384, 3, 1, 1, weight_quant=Int8WeightPerTensorFixedPoint, bias=False, weight_bit_width=8),
            qnn.QuantReLU(act_quant=Int8ActPerTensorFixedPoint, bit_width=8, return_quant_tensor=True),
            qnn.QuantConv2d(384, 256, 3, 1, 1, weight_quant=Int8WeightPerTensorFixedPoint, bias=False, weight_bit_width=8),
            qnn.QuantReLU(act_quant=Int8ActPerTensorFixedPoint, bit_width=8, return_quant_tensor=True),
            nn.MaxPool2d(3, 2)  
        )

        self.classifier = nn.Sequential(
            nn.Dropout(),
            qnn.QuantLinear(256 * 6 * 6, 4096, bias=False, weight_quant=Int8WeightPerTensorFixedPoint, weight_bit_width=8),
            qnn.QuantReLU(act_quant=Int8ActPerTensorFixedPoint, bit_width=8, return_quant_tensor=True),
            nn.Dropout(),
            qnn.QuantLinear(4096, 4096, bias=False, weight_quant=Int8WeightPerTensorFixedPoint, weight_bit_width=8),
            qnn.QuantReLU(act_quant=Int8ActPerTensorFixedPoint, bit_width=8, return_quant_tensor=True),
            qnn.QuantLinear(4096, 1000, output_quant=Int8ActPerTensorFixedPoint, bias=False, weight_quant=Int8WeightPerTensorFixedPoint, weight_bit_width=8),
        )
        
    def forward(self, x):
        out = self.features(x)
        out = torch.flatten(out, 1)
        out = self.classifier(out)
        return out
    

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--train", "-t", help="If explicitly given, the training phase will be executed",
                    action="store_true")
    parser.add_argument("--infer", "-i", help="If explicitly given, the inference phase will be executed",
                    action="store_true")
    parser.add_argument("--batch", "-b", help="The BATCH_SIZE used for the training phase",
                    default=25)
    parser.add_argument("--epochs", "-e", help="The amount of EPOCHS used for the training phase",
                    default=80)
    parser.add_argument("--output", "-o", help="The location in which the model is stored in",
                    default=f"{os.environ['PRJ_TRAIN_PATH']}/Alexnet_qonnx.onnx")
    args = parser.parse_args()
    
    return args


def get_data(args):
    transform = transforms.Compose([
        transforms.Resize((227, 227)),  # Resize images to 227x227
        transforms.ToTensor(),  # Convert images to PyTorch tensors
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),  # Normalize
    ])

    # Load the CIFAR-10 dataset
    training_set = CIFAR10(root=f"{os.environ['PRJ_TRAIN_PATH']}/data", train=True, transform=transform, download=True)
    validation_set = CIFAR10(root=f"{os.environ['PRJ_TRAIN_PATH']}/data", train=False, transform=transform, download=True)

    # Create data loaders
    training_loader = DataLoader(training_set, batch_size=int(args.batch), shuffle=True)
    validation_loader = DataLoader(validation_set, batch_size=int(args.batch), shuffle=False)

    # Report split sizes
    print('Training set has {} instances'.format(len(training_set)))
    print('Validation set has {} instances'.format(len(validation_set))) 

    return (training_set, validation_set, training_loader, validation_loader)



def train(model, args, training_loader, validation_loader):
    loss_fn = nn.CrossEntropyLoss()
    optimizer = torch.optim.SGD(model.parameters(), lr=0.001)

    use_gpu = torch.cuda.is_available()

    def train_one_epoch(epoch_index, training_loader, use_gpu):
        running_loss = 0.
        last_loss = 0.

        # Here, we use enumerate(training_loader) instead of
        # iter(training_loader) so that we can track the batch
        # index and do some intra-epoch reporting
        for i, data in enumerate(training_loader):
            # Every data instance is an input + label pair
            inputs, labels = data
            inputs = inputs.to("cuda:0" if use_gpu else "cpu")
            labels = labels.to("cuda:0" if use_gpu else "cpu")

            # Zero your gradients for every batch!
            optimizer.zero_grad()

            # Make predictions for this batch
            outputs = model(inputs)

            # Compute the loss and its gradients
            loss = loss_fn(outputs, labels)
            loss.backward()

            # Adjust learning weights
            optimizer.step()

            # Gather data and report
            running_loss += loss.item()
            if i % 100 == 99:
                last_loss = running_loss / 100 # loss per batch
                print('  batch {} loss: {}'.format(i + 1, last_loss))
                running_loss = 0.
            
            del inputs
            del labels

        return last_loss

    epoch_number = 0
    best_vloss = 1_000_000.

    print("Start training of", args.epochs, "EPOCHS (batch_size=", args.batch, ")")

    for epoch in range(int(args.epochs)):
        print('EPOCH {}:'.format(epoch_number + 1))

        # Make sure gradient tracking is on, and do a pass over the data
        model.train(True)
        avg_loss = train_one_epoch(epoch_number, training_loader, use_gpu)


        running_vloss = 0.0
        # Set the model to evaluation mode, disabling dropout and using population
        # statistics for batch normalization.
        model.eval()

        # Disable gradient computation and reduce memory consumption.
        with torch.no_grad():
            for i, vdata in enumerate(validation_loader):
                vinputs, vlabels = vdata
                voutputs = model(vinputs.to("cuda:0" if use_gpu else "cpu"))
                vloss = loss_fn(voutputs, vlabels.to("cuda:0" if use_gpu else "cpu"))
                running_vloss += vloss

                del voutputs
                del vlabels

        avg_vloss = running_vloss / (i + 1)
        print('LOSS train {} valid {}'.format(avg_loss, avg_vloss))

        # Track best performance, and save the model's state
        if avg_vloss < best_vloss:
            best_vloss = avg_vloss

        epoch_number += 1

def inference(model, args, validation_loader, batch_amount):
    use_gpu = torch.cuda.is_available()
    latency = 0.0

    total_correct = 0
    total_samples = 0

    torch.cuda.empty_cache()
    import gc
    gc.collect()

    n = batch_amount % len(validation_loader)
    print("Start Inference of", n+1, "batches (batch_size=", args.batch, ")")
    for (i, (images, labels)) in enumerate(validation_loader):
        if i > n:
            break
        # Move the data to the device (CPU or GPU)
        start = time.perf_counter_ns()
        # Forward pass
        outputs = model(images.to("cuda:0" if use_gpu else "cpu"))
        end = time.perf_counter_ns()
        
        latency = float(end - start) / 1000
        _, predicted = torch.max(outputs, 1)

        # Update the running total of correct predictions and samples
        total_correct += (predicted == labels.to("cuda:0" if use_gpu else "cpu")).sum().item()
        total_samples += labels.size(0)

        del outputs
        del predicted
        del labels

    print("total latency", latency)

    # Calculate the accuracy for this epoch
    accuracy = 100 * total_correct / total_samples
    print(f'Accuracy = {accuracy:.2f}%')
    print("Total misses: " + str(total_samples - total_correct) + " of " + str(total_samples))
 
def export_model(model, args):

    return bo.export_qonnx(model, args=torch.randn(1, 3, 227, 227).to('cuda:0' if torch.cuda.is_available() else 'cpu'), export_path=args.output, opset_version=13)


def export_datasets(training_set, validation_set):
    x_val = []
    y_val = []

    x_train = []
    y_train = []

    for (i, (x, y)) in enumerate(validation_set):
        if i >= 1000:
            break
        x_val.append(x.detach().numpy())
        tmp = np.full(shape=(1000, ), fill_value=0)
        tmp[y] = 1
        y_val.append(tmp)


    np.save(f"{os.environ['PRJ_TRAIN_PATH']}/export/cifar-10/x_test.npy", np.array(x_val, dtype=np.float32))
    np.save(f"{os.environ['PRJ_TRAIN_PATH']}/export/cifar-10/y_test.npy", np.array(y_val, dtype=np.float32))

    del x_val
    del y_val

    for (i, (x, y)) in enumerate(training_set):
        if i >= 1000:
            break
        x_train.append(x.detach().numpy())
        tmp = np.full(shape=(1000, ), fill_value=0)
        tmp[y] = 1
        y_train.append(tmp)

    np.save(f"{os.environ['PRJ_TRAIN_PATH']}/export/cifar-10/x_train.npy", np.array(x_train, dtype=np.float32))
    np.save(f"{os.environ['PRJ_TRAIN_PATH']}/export/cifar-10/y_train.npy", np.array(y_train, dtype=np.float32))


def main():
    args = parse_arguments()

    model = QuantAlexNet()

    use_gpu = torch.cuda.is_available()
    if use_gpu:
        model = model.cuda()
        print("USE GPU")
    else:
        print("USE CPU")

    (training_set, validation_set, training_loader, validation_loader) = get_data(args)
    
    export_datasets(training_set, validation_set)

    if args.train or (not args.train and not args.infer):
        train(model, args, training_loader, validation_loader)
        export_model(model, args)

    del training_loader

    if args.infer or (not args.train and not args.infer):
        # model export does not work, because this operation is not implemented for quantized models...
        #model = model if args.train or (not args.train and not args.infer) else ConvertModel(onnx.load(args.output)).cuda()
        inference(model, args, validation_loader, -1)
        inference(model, args, validation_loader, 39)

if __name__ == "__main__":
    main() 

