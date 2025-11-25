#include "mem_interface.h"

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
// Interrupt libraries
#include "xinterrupt_wrap.h"
}


/************************** Constant Definitions *****************************/

/*
 * Device hardware build related constants.
 */


#ifdef XPAR_MEM0_BASEADDRESS
#define DDR_BASE_ADDR XPAR_MEM0_BASEADDRESS
#endif


#ifndef DDR_BASE_ADDR
#warning CHECK FOR THE VALID DDR ADDRESS IN XPARAMETERS.H, \
DEFAULT SET TO 0x01000000
#define MEM_BASE_ADDR 0x02000000
#else
#define MEM_BASE_ADDR (DDR_BASE_ADDR + 0x1000000)
#endif

#define DMA_PX_TX_INTR_ID XPAR_FABRIC_AXI_DMA_0_INTR     // MM2S channel
#define DMA_PX_RX_INTR_ID XPAR_FABRIC_AXI_DMA_0_INTR_1   // S2MM channel
#define DMA_WT_RX_INTR_ID XPAR_FABRIC_AXI_DMA_1_INTR     // S2MM only


#define TX_CFG_BUFFER_BASE (MEM_BASE_ADDR + 0x00600000)
#define TX_WT_BUFFER_BASE (MEM_BASE_ADDR + 0x00100000)
#define TX_PX_BUFFER_BASE (MEM_BASE_ADDR + 0x00200000)
#define RX_PX_BUFFER_BASE (MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH (MEM_BASE_ADDR + 0x005FFFFF)

// time_out loop counter for reset

#define MAX_PKT_LEN		0x100

#define NUMBER_OF_TRANSFERS	10

#define RESET_TIMEOUT_COUNTER 10000
#define POLL_TIMEOUT_COUNTER 100U
#define NUMBER_OF_EVENTS 1

static void tx_wt_intr_handler(void *callback);
static void tx_px_intr_handler(void *callback);
static void rx_intr_handler(void *callback);

// uncomment to enable debug
//#define ACC_INTERFACE_DBG

MemInterface MemInterface::instance;

MemInterface::MemInterface() {
    int status_wt, status_px;

    config_wt = XAxiDma_LookupConfig(XPAR_XAXIDMA_1_BASEADDR);
    config_px = XAxiDma_LookupConfig(XPAR_XAXIDMA_0_BASEADDR);
    if (!config_wt) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("No config found for %d\r\n", XPAR_XAXIDMA_1_BASEADDR);
#endif
        throw std::runtime_error("No config found");
    }
    if (!config_px) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("No config found for %d\r\n", XPAR_XAXIDMA_0_BASEADDR);
#endif
        throw std::runtime_error("No config found");
    }

    // Initialize DMA engine
    status_wt = XAxiDma_CfgInitialize(&axi_dma_wt, config_wt);
    status_px = XAxiDma_CfgInitialize(&axi_dma_px, config_px);

    if (status_wt != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Initialization failed %d\r\n", status_wt);
#endif
        throw std::runtime_error("Initialization failed");
    }

    if (status_px != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Initialization failed %d\r\n", status_px);
#endif
        throw std::runtime_error("Initialization failed");
    }

    if (XAxiDma_HasSg(&axi_dma_wt)) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Device axi_dma_wt configured as SG mode \r\n");
#endif
    }

    if (XAxiDma_HasSg(&axi_dma_px)) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Device axi_dma_px configured as SG mode \r\n");
#endif
    }

    // Set up Interrupt system
    status_px =
        XSetupInterruptSystem(static_cast<void *>(&axi_dma_px), reinterpret_cast<void *>(&tx_px_intr_handler), config_px->IntrId[0],
                              config_px->IntrParent, XINTERRUPT_DEFAULT_PRIORITY);
    if (status_px != XST_SUCCESS) {
        throw std::runtime_error("Could not setup interrupt system for Pixel DMA");
    }

    status_px =
        XSetupInterruptSystem(static_cast<void *>(&axi_dma_px), reinterpret_cast<void *>(&rx_intr_handler), config_px->IntrId[1],
                              config_px->IntrParent, XINTERRUPT_DEFAULT_PRIORITY);
    if (status_px != XST_SUCCESS) {
        throw std::runtime_error("Could not setup interrupt system for Pixel DMA");
    }

    status_wt =
        XSetupInterruptSystem(static_cast<void *>(&axi_dma_wt), reinterpret_cast<void *>(&tx_wt_intr_handler), config_wt->IntrId[0],
                              config_wt->IntrParent, XINTERRUPT_DEFAULT_PRIORITY);
    if (status_wt != XST_SUCCESS) {
        throw std::runtime_error("Could not setup interrupt system for Weight DMA");
    }

    // Disable all interrupts before setup
    XAxiDma_IntrDisable(&axi_dma_px, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(&axi_dma_px, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    XAxiDma_IntrDisable(&axi_dma_wt, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(&axi_dma_wt, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    // Enable interrupts
    XAxiDma_IntrEnable(&axi_dma_px, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrEnable(&axi_dma_px, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    XAxiDma_IntrEnable(&axi_dma_wt, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrEnable(&axi_dma_wt, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

}

struct MemResult MemInterface::run() {
#ifdef ACC_INTERFACE_DBG
    xil_printf("MemInterface run\r\n");
#endif

    int status;
    u8 *cfg_ptr = reinterpret_cast<u8*>(TX_CFG_BUFFER_BASE);
    u8 *wt_ptr = reinterpret_cast<u8*>(TX_WT_BUFFER_BASE);
    u8 *px_ptr = reinterpret_cast<u8*>(TX_PX_BUFFER_BASE);
    u8 *result_ptr_px = reinterpret_cast<u8*>(RX_PX_BUFFER_BASE);

    tx_wt_iteration = 0;
    tx_px_iteration = 0;
    rx_iteration = 0;

    cfg_done = 0;
    tx_wt_done = 0;
    tx_px_done = 0;
    rx_done = 0;
    
    error = 0;

    int result_length = ((u32)((u16 *)cfg_ptr)[1]) * ((u16 *)cfg_ptr)[1] * ((u16 *)cfg_ptr)[3];

    // Flush the buffers before the DMA transfer, in case the Data Cache is enabled
    Xil_DCacheFlushRange(reinterpret_cast<UINTPTR>(cfg_ptr), 128);
    Xil_DCacheFlushRange(reinterpret_cast<UINTPTR>(px_ptr), ((u32)((u16 *)cfg_ptr)[0]) * ((u16 *)cfg_ptr)[0] * ((u16 *)cfg_ptr)[2]);
    Xil_DCacheFlushRange(reinterpret_cast<UINTPTR>(wt_ptr), ((u32)cfg_ptr[12]) * cfg_ptr[12] * ((u16 *)cfg_ptr)[2] * ((u16 *)cfg_ptr)[3]);
    Xil_DCacheFlushRange(reinterpret_cast<UINTPTR>(result_ptr_px), result_length);

#ifdef ACC_INTERFACE_DBG
    xil_printf("MemInterface GetTime start\r\n");
#endif

    XTime start_time;
    XTime_GetTime(&start_time);

    // start receive of first output channel
    status = XAxiDma_SimpleTransfer(&axi_dma_px, reinterpret_cast<UINTPTR>(result_ptr_px), ((u16 *)cfg_ptr)[4],
                                    XAXIDMA_DEVICE_TO_DMA);

    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("rx_buffer init transfer was not successful for pixels %d\r\n", status);
#endif
        struct MemResult res = {
            true,  // error
            0,     // time_ns
            result_length,
            result_ptr_px           // result
        };

        return res;
    }

        // send pixel data
#ifdef ACC_INTERFACE_DBG
        xil_printf("Amount of Pixel data to be send %d\r\n", ((u32)((u16 *)cfg_ptr)[0]) * ((u16 *)cfg_ptr)[0] * ((u16 *)cfg_ptr)[2]);
#endif    
    status = XAxiDma_SimpleTransfer(&axi_dma_px, reinterpret_cast<UINTPTR>(px_ptr), ((u32)((u16 *)cfg_ptr)[0]) * ((u16 *)cfg_ptr)[0] * ((u16 *)cfg_ptr)[2],
                                    XAXIDMA_DMA_TO_DEVICE);

    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("tx_buffer transfer Pixels was not successful %d\r\n", status);
#endif
        struct MemResult res = {
            true,  // error
            0,     // time_ns
            result_length,
            result_ptr_px           // result
        };

        return res;
    }

    // send configuration string
    status = XAxiDma_SimpleTransfer(&axi_dma_wt, reinterpret_cast<UINTPTR>(cfg_ptr), 16 * sizeof(u8),
                                    XAXIDMA_DMA_TO_DEVICE);

    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("tx_buffer_cfg transfer was not successful for config string %d\r\n", status);
#endif
        struct MemResult res = {
            true,  // error
            0,     // time_ns
            result_length,
            result_ptr_px           // result
        };

        return res;
    }

    status = Xil_WaitForEventSet(POLL_TIMEOUT_COUNTER, NUMBER_OF_EVENTS, &error);
    if (status == XST_SUCCESS) {
        if (!tx_wt_done || !tx_px_done) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("Transmit error %d\r\n", status);
#endif
        } else if (!rx_done) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("Receive error %d\r\n", status);
#endif
        }

        struct MemResult res = {
            true,  // error
            0,     // time_ns
            result_length,
            result_ptr_px           // result
        };

        return res;
    }

    // Wait for RX done or time_out
    status = Xil_WaitForEventSet(POLL_TIMEOUT_COUNTER * 80 * 128, NUMBER_OF_EVENTS, &rx_done);
    if (status != XST_SUCCESS) {
//#ifdef ACC_INTERFACE_DBG
        xil_printf("Receive failed %d\r\n", status);
//#endif

        struct MemResult res = {
            true,  // error
            0,     // time_ns
            result_length,
            result_ptr_px           // result
        };

        return res;
    }

#ifdef ACC_INTERFACE_DBG
    xil_printf("MemInterface Done\r\n");
#endif


    u64 time_ns = ((end_time - start_time) * 1000 * 1000 * 1000) / (COUNTS_PER_SECOND);

    struct MemResult res = {
        false,                  // error
        time_ns,                // time_ns
        result_length,
        result_ptr_px           // result
    };

    return res;
}

MemInterface::~MemInterface() {
    XDisconnectInterruptCntrl(config_px->IntrId[0], config_px->IntrParent);
    XDisconnectInterruptCntrl(config_px->IntrId[1], config_px->IntrParent);
    XDisconnectInterruptCntrl(config_wt->IntrId[0], config_wt->IntrParent);
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
static void tx_wt_intr_handler(void *callback) {

#ifdef ACC_INTERFACE_DBG
    xil_printf("MemInterface tx_wt_intr_handler\r\n");
#endif
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

        MemInterface::instance.error = 1;
        

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
        // Config or weight data has been sent and received by unit, start sending next weight data
        u8 *cfg_ptr = reinterpret_cast<u8*>(TX_CFG_BUFFER_BASE);
        u8 *wt_ptr = reinterpret_cast<u8*>(TX_WT_BUFFER_BASE);
        
        size_t iter_id = MemInterface::instance.tx_wt_iteration;
        if (iter_id <= ((u16 *)cfg_ptr)[3] * (((u16 *)cfg_ptr)[2] / ((u16 *)cfg_ptr)[5])) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("tx_wt_intr_handler iteration %d : successful!\r\n", MemInterface::instance.tx_wt_iteration);
#endif
        
            u32 weight_amount_per_iteration = ((u32)cfg_ptr[12]) * cfg_ptr[12] * ((u16 *)cfg_ptr)[5];
            int status = XAxiDma_SimpleTransfer(&MemInterface::instance.axi_dma_wt, reinterpret_cast<UINTPTR>(wt_ptr), weight_amount_per_iteration,
                        XAXIDMA_DMA_TO_DEVICE);

            if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
                xil_printf("Weight send process Nr. %d was not successful with status %d\r\n", MemInterface::instance.tx_wt_iteration, status);
#endif
                MemInterface::instance.error = 1;

            }

            MemInterface::instance.tx_wt_iteration++;
        } else {
            // all weight data has been sent
#ifdef ACC_INTERFACE_DBG
            xil_printf("tx_wt_intr_handler iteration FINAL : finished successfully!\r\n");
#endif
            MemInterface::instance.tx_wt_done = 1;
        }
    }
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
static void tx_px_intr_handler(void *callback) {

#ifdef ACC_INTERFACE_DBG
    xil_printf("MemInterface tx_px_intr_handler\r\n");
#endif

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

        MemInterface::instance.error = 1;
        

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
        // Config or weight data has been sent and received by unit, start sending next weight data
        u8 *cfg_ptr = reinterpret_cast<u8*>(TX_CFG_BUFFER_BASE);

        size_t iter_id = MemInterface::instance.tx_px_iteration;

        if (iter_id < ((u16 *)cfg_ptr)[3] - 1) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("tx_px_intr_handler iteration %d : successful!\r\n", MemInterface::instance.tx_px_iteration);
#endif
            MemInterface::instance.tx_px_iteration++;
        } else {
#ifdef ACC_INTERFACE_DBG
            xil_printf("tx_px_intr_handler iteration FINAL : finished successfully!\r\n");
#endif
            // the pixel data has been sent output channel many times
            MemInterface::instance.tx_px_done = 1;
        }
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

#ifdef ACC_INTERFACE_DBG
    xil_printf("MemInterface rx_intr_handler\r\n");
#endif

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
        MemInterface::instance.error = 1;

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
        // Config or weight data has been sent and received by unit, start sending next weight data
        u8 *cfg_ptr = reinterpret_cast<u8*>(TX_CFG_BUFFER_BASE);
        u8 *px_ptr = reinterpret_cast<u8*>(TX_PX_BUFFER_BASE);
        u8 *rx_ptr = reinterpret_cast<u8*>(RX_PX_BUFFER_BASE);
        size_t iter_id = MemInterface::instance.rx_iteration;
#ifdef ACC_INTERFACE_DBG
        xil_printf("rx_intr_handler iteration %d : successful!\r\n", MemInterface::instance.rx_iteration);
#endif
        if (iter_id < ((u16 *)cfg_ptr)[3] - 1) {
            MemInterface::instance.rx_iteration++;
            // start receive of next output channel
            int status = XAxiDma_SimpleTransfer(&MemInterface::instance.axi_dma_px, reinterpret_cast<UINTPTR>(rx_ptr), ((u16 *)cfg_ptr)[4],
                                    XAXIDMA_DEVICE_TO_DMA);

            if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("Iteration %d : tx_buffer Pixels RX could not be received with status %d\r\n", MemInterface::instance.rx_iteration, status);
#endif
            }

            // send pixel data again
            status = XAxiDma_SimpleTransfer(&MemInterface::instance.axi_dma_px, reinterpret_cast<UINTPTR>(px_ptr), ((u16 *)cfg_ptr)[0] * ((u16 *)cfg_ptr)[0] * ((u16 *)cfg_ptr)[2],
                                    XAXIDMA_DMA_TO_DEVICE);

            if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("Iteration %d : tx_buffer Pixels TX could not be send with status %d\r\n", MemInterface::instance.rx_iteration, status);
#endif
            }

        }
        else {
#ifdef ACC_INTERFACE_DBG
            xil_printf("rx_intr_handler iteration FINAL : finished successfully!\r\n");
#endif
            // Get time in two steps because of volatile qualifier of end_time
            XTime tmp;
            XTime_GetTime(&tmp);
            MemInterface::instance.end_time = tmp;

            MemInterface::instance.rx_done = 1;
        }
    }
}
