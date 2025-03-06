#include "acc_interface.h"

#include <stdint.h>
#include <xil_types.h>

#include <stdexcept>

// include C APIs
extern "C" {
#include "xaxidma.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xil_util.h"
#include "xiltimer.h"
#ifdef SDT
#include "xinterrupt_wrap.h"
#endif

#ifndef SDT
#ifdef XPAR_INTC_0_DEVICE_ID
#include "xintc.h"
#else
#include "xscugic.h"
#endif
#endif
}


/************************** Constant Definitions *****************************/

/*
 * Device hardware build related constants.
 */

#ifndef SDT
#define DMA_DEV_ID XPAR_AXIDMA_0_DEVICE_ID

#ifdef XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#define DDR_BASE_ADDR XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#elif defined(XPAR_MIG7SERIES_0_BASEADDR)
#define DDR_BASE_ADDR XPAR_MIG7SERIES_0_BASEADDR
#elif defined(XPAR_MIG_0_C0_DDR4_MEMORY_MAP_BASEADDR)
#define DDR_BASE_ADDR XPAR_MIG_0_C0_DDR4_MEMORY_MAP_BASEADDR
#elif defined(XPAR_PSU_DDR_0_S_AXI_BASEADDR)
#define DDR_BASE_ADDR XPAR_PSU_DDR_0_S_AXI_BASEADDR
#endif

#else

#ifdef XPAR_MEM0_BASEADDRESS
#define DDR_BASE_ADDR XPAR_MEM0_BASEADDRESS
#endif

#endif

#ifndef DDR_BASE_ADDR
#warning CHECK FOR THE VALID DDR ADDRESS IN XPARAMETERS.H, \
DEFAULT SET TO 0x01000000
#define MEM_BASE_ADDR 0x01000000
#else
#define MEM_BASE_ADDR (DDR_BASE_ADDR + 0x1000000)
#endif

#ifndef SDT
#ifdef XPAR_INTC_0_DEVICE_ID
#define RX_INTR_ID XPAR_INTC_0_AXIDMA_0_S2MM_INTROUT_VEC_ID
#define TX_INTR_ID XPAR_INTC_0_AXIDMA_0_MM2S_INTROUT_VEC_ID
#else
#define RX_INTR_ID XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID
#define TX_INTR_ID XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID
#endif
#endif

#define TX_BUFFER_BASE (MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE (MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH (MEM_BASE_ADDR + 0x004FFFFF)

#ifndef SDT
#ifdef XPAR_INTC_0_DEVICE_ID
#define INTC_DEVICE_ID XPAR_INTC_0_DEVICE_ID
#else
#define INTC_DEVICE_ID XPAR_SCUGIC_SINGLE_DEVICE_ID
#endif

#ifdef XPAR_INTC_0_DEVICE_ID
#define INTC XIntc
#define INTC_HANDLER XIntc_InterruptHandler
#else
#define INTC XScuGic
#define INTC_HANDLER XScuGic_InterruptHandler
#endif
#endif

// time_out loop counter for reset
#define RESET_TIMEOUT_COUNTER 10000
#define POLL_TIMEOUT_COUNTER 1000000U
#define NUMBER_OF_EVENTS 1

static void tx_intr_handler(void *callback);
static void rx_intr_handler(void *callback);

#ifndef SDT
static int setup_intr_system(INTC *IntcInstancePtr, XAxiDma *AxiDmaPtr,
                             u16 TxIntrId, u16 RxIntrId);
static void disable_intr_system(INTC *IntcInstancePtr, u16 TxIntrId,
                                u16 RxIntrId);

#endif

// uncomment to enable debug
#define ACC_INTERFACE_DBG

AccInterface AccInterface::instance;

AccInterface::AccInterface() {
        int status;

#ifndef SDT
    config = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!config) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("No config found for %d\r\n", DMA_DEV_ID);
#endif

        throw std::runtime_error("No config found");
    }
#else
    config = XAxiDma_LookupConfig(XPAR_XAXIDMA_0_BASEADDR);
    if (!config) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("No config found for %d\r\n", XPAR_XAXIDMA_0_BASEADDR);
#endif

        throw std::runtime_error("No config found");
    }
#endif

    // Initialize DMA engine
    status = XAxiDma_CfgInitialize(&axi_dma, config);

    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Initialization failed %d\r\n", status);
#endif
        throw std::runtime_error("Initialization failed");
    }

    if (XAxiDma_HasSg(&axi_dma)) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Device configured as SG mode \r\n");
#endif
    }

    // Set up Interrupt system
#ifndef SDT
    status = setup_intr_system(&intc, &axi_dma, TX_INTR_ID, RX_INTR_ID);
    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Failed intr setup\r\n");
#endif

        throw std::runtime_error("Failed intr setup");
    }
#else
    status =
        XSetupInterruptSystem(static_cast<void *>(&axi_dma), reinterpret_cast<void *>(&tx_intr_handler), config->IntrId[0],
                              config->IntrParent, XINTERRUPT_DEFAULT_PRIORITY);
    if (status != XST_SUCCESS) {
        throw std::runtime_error("Could not setup interrupt system");
    }

    status =
        XSetupInterruptSystem(static_cast<void *>(&axi_dma), reinterpret_cast<void *>(&rx_intr_handler), config->IntrId[1],
                              config->IntrParent, XINTERRUPT_DEFAULT_PRIORITY);
    if (status != XST_SUCCESS) {
        throw std::runtime_error("Could not setup interrupt system");
    }
#endif

    // Disable all interrupts before setup
    XAxiDma_IntrDisable(&axi_dma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(&axi_dma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    // Enable all interrupts
    XAxiDma_IntrEnable(&axi_dma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrEnable(&axi_dma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
}

struct AccResult AccInterface::run(u8 *tx_buffer, int length) {
    int status;
    int* result_ptr = reinterpret_cast<int*>(0x01000000 + 0x00300000);
    *result_ptr = 0;

    tx_done = 0;
    rx_done = 0;
    error = 0;

    // Flush the buffers before the DMA transfer, in case the Data Cache is enabled
    Xil_DCacheFlushRange(reinterpret_cast<UINTPTR>(tx_buffer), length);
    Xil_DCacheFlushRange(reinterpret_cast<UINTPTR>(result_ptr), 1);

    XTime start_time;
    XTime_GetTime(&start_time);

    status = XAxiDma_SimpleTransfer(&axi_dma, reinterpret_cast<UINTPTR>(result_ptr), 1,
                                    XAXIDMA_DEVICE_TO_DMA);

    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("rx_buffer transfer was not successful %d", status);
#endif
        struct AccResult res = {
            true,  // error
            0,     // time_ns
            0,     // result
        };

        return res;
    }

    status = XAxiDma_SimpleTransfer(&axi_dma, reinterpret_cast<UINTPTR>(tx_buffer), length,
                                    XAXIDMA_DMA_TO_DEVICE);

    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("tx_buffer transfer was not successful %d", status);
#endif
        struct AccResult res = {
            true,  // error
            0,     // time_ns
            0,     // result
        };

        return res;
    }

    status = Xil_WaitForEventSet(POLL_TIMEOUT_COUNTER, NUMBER_OF_EVENTS, &error);
    if (status == XST_SUCCESS) {
        if (!tx_done) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("Transmit error %d\r\n", status);
#endif
        } else if (status == XST_SUCCESS && !rx_done) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("Receive error %d\r\n", status);
#endif
        }

        struct AccResult res = {
            true,  // error
            0,     // time_ns
            0,     // result
        };

        return res;
    }

    // Wait for TX done or time_out
    status = Xil_WaitForEventSet(POLL_TIMEOUT_COUNTER, NUMBER_OF_EVENTS, &tx_done);
    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Transmit failed %d\r\n", status);
#endif
        struct AccResult res = {
            true,  // error
            0,     // time_ns
            0,     // result
        };

        return res;
    }

    // Wait for RX done or time_out
    status = Xil_WaitForEventSet(POLL_TIMEOUT_COUNTER, NUMBER_OF_EVENTS, &rx_done);
    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Receive failed %d\r\n", status);
#endif

        struct AccResult res = {
            true,  // error
            0,     // time_ns
            0,     // result
        };

        return res;
    }

    u64 time_ns = ((end_time - start_time) * 1000 * 1000 * 1000) / (COUNTS_PER_SECOND);

    struct AccResult res = {
        false,    // error
        time_ns,  // time_ns
        static_cast<u8>(*result_ptr)    // result
    };

    return res;
}

AccInterface::~AccInterface() {
    // Disable TX and RX Ring interrupts and return success
#ifndef SDT
    disable_intr_system(&intc, TX_INTR_ID, RX_INTR_ID);
#else
    XDisconnectInterruptCntrl(config->IntrId[0], config->IntrParent);
    XDisconnectInterruptCntrl(config->IntrId[1], config->IntrParent);
#endif
}

/*****************************************************************************/
/*
 *
 * This is the DMA TX Interrupt handler function.
 *
 * It gets the interrupt status from the hardware, acknowledges it, and if any
 * error happens, it resets the hardware. Otherwise, if a completion interrupt
 * is present, then sets the TxDone.flag
 *
 * @param	callback is a pointer to TX channel of the DMA engine.
 *
 * @return	None.
 *
 * @note		None.
 *
 ******************************************************************************/
static void tx_intr_handler(void *callback) {
    u32 irq_status;
    int time_out;
    XAxiDma *axi_dma_inst = (XAxiDma *)callback;

    // Read pending interrupts
    irq_status = XAxiDma_IntrGetIrq(axi_dma_inst, XAXIDMA_DMA_TO_DEVICE);

    // Acknowledge pending interrupts

    XAxiDma_IntrAckIrq(axi_dma_inst, irq_status, XAXIDMA_DMA_TO_DEVICE);

    // If no interrupt is asserted, we do not do anything
    if (!(irq_status & XAXIDMA_IRQ_ALL_MASK)) {
        return;
    }

    // If error interrupt is asserted, raise error flag, reset the
    // hardware to recover from the error, and return with no further
    // processing.
    if ((irq_status & XAXIDMA_IRQ_ERROR_MASK)) {
        AccInterface::instance.error = 1;

        // Reset should never fail for transmit channel
        XAxiDma_Reset(axi_dma_inst);

        time_out = RESET_TIMEOUT_COUNTER;

        while (time_out) {
            if (XAxiDma_ResetIsDone(axi_dma_inst)) {
                break;
            }

            time_out -= 1;
        }

        return;
    }

    // If Completion interrupt is asserted, then set the TxDone flag
    if ((irq_status & XAXIDMA_IRQ_IOC_MASK)) {
        AccInterface::instance.tx_done = 1;
    }
}

/*****************************************************************************/
/*
 *
 * This is the DMA RX interrupt handler function
 *
 * It gets the interrupt status from the hardware, acknowledges it, and if any
 * error happens, it resets the hardware. Otherwise, if a completion interrupt
 * is present, then it sets the RxDone flag.
 *
 * @param	callback is a pointer to RX channel of the DMA engine.
 *
 * @return	None.
 *
 * @note		None.
 *
 ******************************************************************************/
static void rx_intr_handler(void *callback) {
    u32 irq_status;
    int time_out;
    XAxiDma *axi_dma_inst = (XAxiDma *)callback;

    // Read pending interrupts
    irq_status = XAxiDma_IntrGetIrq(axi_dma_inst, XAXIDMA_DEVICE_TO_DMA);

    // Acknowledge pending interrupts
    XAxiDma_IntrAckIrq(axi_dma_inst, irq_status, XAXIDMA_DEVICE_TO_DMA);

    // If no interrupt is asserted, we do not do anything
    if (!(irq_status & XAXIDMA_IRQ_ALL_MASK)) {
        return;
    }

    // If error interrupt is asserted, raise error flag, reset the
    // hardware to recover from the error, and return with no further
    // processing.
    if ((irq_status & XAXIDMA_IRQ_ERROR_MASK)) {
        AccInterface::instance.error = 1;

        // Reset could fail and hang NEED a way to handle this or do not call it??
        XAxiDma_Reset(axi_dma_inst);

        time_out = RESET_TIMEOUT_COUNTER;

        while (time_out) {
            if (XAxiDma_ResetIsDone(axi_dma_inst)) {
                break;
            }

            time_out -= 1;
        }

        return;
    }

    // If completion interrupt is asserted, then set RxDone flag
    if ((irq_status & XAXIDMA_IRQ_IOC_MASK)) {
        // Get time in two steps because of volatile qualifier of end_time
        XTime tmp;
        XTime_GetTime(&tmp);
        AccInterface::instance.end_time = tmp;

        AccInterface::instance.rx_done = 1;
    }
}
#ifndef SDT
/*****************************************************************************/
/*
 *
 * This function setups the interrupt system so interrupts can occur for the
 * DMA, it assumes INTC component exists in the hardware system.
 *
 * @param	IntcInstancePtr is a pointer to the instance of the INTC.
 * @param	AxiDmaPtr is a pointer to the instance of the DMA engine
 * @param	TxIntrId is the TX channel Interrupt ID.
 * @param	RxIntrId is the RX channel Interrupt ID.
 *
 * @return
 *		- XST_SUCCESS if successful,
 *		- XST_FAILURE.if not successful
 *
 * @note		None.
 *
 ******************************************************************************/
static int setup_intr_system(INTC *IntcInstancePtr, XAxiDma *AxiDmaPtr,
                             u16 TxIntrId, u16 RxIntrId) {
    int status;

#ifdef XPAR_INTC_0_DEVICE_ID

    // Initialize the interrupt controller and connect the ISRs
    status = XIntc_Initialize(IntcInstancePtr, INTC_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("Failed init intc\r\n");
        return XST_FAILURE;
    }

    status = XIntc_Connect(IntcInstancePtr, TxIntrId,
                           (XInterruptHandler)tx_intr_handler, AxiDmaPtr);
    if (status != XST_SUCCESS) {
        xil_printf("Failed tx connect intc\r\n");
        return XST_FAILURE;
    }

    status = XIntc_Connect(IntcInstancePtr, RxIntrId,
                           (XInterruptHandler)rx_intr_handler, AxiDmaPtr);
    if (status != XST_SUCCESS) {
        xil_printf("Failed rx connect intc\r\n");
        return XST_FAILURE;
    }

    // Start the interrupt controller
    status = XIntc_Start(IntcInstancePtr, XIN_REAL_MODE);
    if (status != XST_SUCCESS) {
        xil_printf("Failed to start intc\r\n");
        return XST_FAILURE;
    }

    XIntc_Enable(IntcInstancePtr, TxIntrId);
    XIntc_Enable(IntcInstancePtr, RxIntrId);

#else

    XScuGic_Config *IntcConfig;

    // Initialize the interrupt controller driver so that it is ready to use.
    IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (NULL == IntcConfig) {
        return XST_FAILURE;
    }

    status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig,
                                   IntcConfig->CpuBaseAddress);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XScuGic_SetPriorityTriggerType(IntcInstancePtr, TxIntrId, 0xA0, 0x3);

    XScuGic_SetPriorityTriggerType(IntcInstancePtr, RxIntrId, 0xA0, 0x3);

    // Connect the device driver handler that will be called when an
    // interrupt for the device occurs, the handler defined above performs
    // the specific interrupt processing for the device.
    status = XScuGic_Connect(IntcInstancePtr, TxIntrId,
                             (Xil_InterruptHandler)tx_intr_handler, AxiDmaPtr);
    if (status != XST_SUCCESS) {
        return status;
    }

    status = XScuGic_Connect(IntcInstancePtr, RxIntrId,
                             (Xil_InterruptHandler)rx_intr_handler, AxiDmaPtr);
    if (status != XST_SUCCESS) {
        return status;
    }

    XScuGic_Enable(IntcInstancePtr, TxIntrId);
    XScuGic_Enable(IntcInstancePtr, RxIntrId);

#endif

    // Enable interrupts from the hardware

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                 (Xil_ExceptionHandler)INTC_HANDLER,
                                 (void *)IntcInstancePtr);

    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

/*****************************************************************************/
/**
 *
 * This function disables the interrupts for DMA engine.
 *
 * @param	IntcInstancePtr is the pointer to the INTC component instance
 * @param	TxIntrId is interrupt ID associated w/ DMA TX channel
 * @param	RxIntrId is interrupt ID associated w/ DMA RX channel
 *
 * @return	None.
 *
 * @note		None.
 *
 ******************************************************************************/
static void disable_intr_system(INTC *IntcInstancePtr, u16 TxIntrId,
                                u16 RxIntrId) {
#ifdef XPAR_INTC_0_DEVICE_ID
    // Disconnect the interrupts for the DMA TX and RX channels
    XIntc_Disconnect(IntcInstancePtr, TxIntrId);
    XIntc_Disconnect(IntcInstancePtr, RxIntrId);
#else
    XScuGic_Disconnect(IntcInstancePtr, TxIntrId);
    XScuGic_Disconnect(IntcInstancePtr, RxIntrId);
#endif
}
#endif