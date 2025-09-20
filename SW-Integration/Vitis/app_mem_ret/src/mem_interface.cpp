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


#define DMA_PX_ID XPAR_AXIDMA_0_DEVICE_ID
#define DMA_WT_ID XPAR_AXIDMA_1_DEVICE_ID

#ifdef XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#define DDR_BASE_ADDR XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#elif defined(XPAR_MIG7SERIES_0_BASEADDR)
#define DDR_BASE_ADDR XPAR_MIG7SERIES_0_BASEADDR
#elif defined(XPAR_MIG_0_C0_DDR4_MEMORY_MAP_BASEADDR)
#define DDR_BASE_ADDR XPAR_MIG_0_C0_DDR4_MEMORY_MAP_BASEADDR
#elif defined(XPAR_PSU_DDR_0_S_AXI_BASEADDR)
#define DDR_BASE_ADDR XPAR_PSU_DDR_0_S_AXI_BASEADDR
#endif


#ifndef DDR_BASE_ADDR
#warning CHECK FOR THE VALID DDR ADDRESS IN XPARAMETERS.H, \
DEFAULT SET TO 0x01000000
#define MEM_BASE_ADDR 0x01000000
#else
#define MEM_BASE_ADDR (DDR_BASE_ADDR + 0x1000000)
#endif

#define DMA_PX_TX_INTR_ID XPAR_FABRIC_AXI_DMA_0_INTR     // MM2S channel
#define DMA_PX_RX_INTR_ID XPAR_FABRIC_AXI_DMA_0_INTR_1   // S2MM channel
#define DMA_WT_RX_INTR_ID XPAR_FABRIC_AXI_DMA_1_INTR     // S2MM only


#define TX_WT_BUFFER_BASE (MEM_BASE_ADDR + 0x00100000)
#define TX_PX_BUFFER_BASE (MEM_BASE_ADDR + 0x00200000)
#define RX_PX_BUFFER_BASE (MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH (MEM_BASE_ADDR + 0x005FFFFF)

#define INTC_DEVICE_ID XPAR_SCUGIC_SINGLE_DEVICE_ID

#define INTC XScuGic
#define INTC_HANDLER XScuGic_InterruptHandler

// time_out loop counter for reset

#define MAX_PKT_LEN		0x100

#define NUMBER_OF_TRANSFERS	10

#define RESET_TIMEOUT_COUNTER 10000
#define POLL_TIMEOUT_COUNTER 100U
#define NUMBER_OF_EVENTS 1

static void tx_intr_handler(void *callback);
static void rx_intr_handler(void *callback);

static int setup_intr_system(INTC *IntcInstancePtr, XAxiDma *AxiDmaPtr,
                             u16 TxIntrId, u16 RxIntrId);
static void disable_intr_system(INTC *IntcInstancePtr, u16 TxIntrId,
                                u16 RxIntrId);

// uncomment to enable debug
#define ACC_INTERFACE_DBG

AccInterface AccInterface::instance;

AccInterface::AccInterface() {
    int status_wt, status_px;

    config_wt = XAxiDma_LookupConfig(DMA_WT_ID);
    config_px = XAxiDma_LookupConfig(DMA_PX_ID);
    if (!config_wt) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("No config found for %d\r\n", DMA_WT_ID);
#endif
        throw std::runtime_error("No config found");
    }
    if (!config_px) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("No config found for %d\r\n", DMA_WT_ID);
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
        xil_printf("Device %d configured as SG mode \r\n", DMA_WT_ID);
#endif
    }

    if (XAxiDma_HasSg(&axi_dma_px)) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Device %d configured as SG mode \r\n", DMA_PX_ID);
#endif
    }

    // Set up Interrupt system
    status_wt = setup_intr_system(&intc, &axi_dma_wt, 0xFFFF, DMA_WT_RX_INTR_ID);
    if (status_wt != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Failed intr setup for %d\r\n", DMA_WT_ID);
#endif

        throw std::runtime_error("Failed intr setup");
    }

    // Set up Interrupt system
    status_px = setup_intr_system(&intc, &axi_dma_px, DMA_PX_TX_INTR_ID, DMA_PX_RX_INTR_ID);
    if (status_px != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Failed intr setup for %d\r\n", DMA_PX_ID);
#endif

        throw std::runtime_error("Failed intr setup");
    }


    // Disable all interrupts before setup
    XAxiDma_IntrDisable(&axi_dma_px, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(&axi_dma_px, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    XAxiDma_IntrDisable(&axi_dma_wt, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(&axi_dma_wt, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    // Enable interrupts
    XAxiDma_IntrEnable(&axi_dma_px, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrEnable(&axi_dma_px, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    XAxiDma_IntrEnable(&axi_dma_wt, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

}

struct MemResult MemInterface::run(u8 *tx_buffer_wt, u8 *tx_buffer_px) {
#ifdef ACC_INTERFACE_DBG
    xil_printf("MemInterface run\r\n");
#endif

    int status;
    u8 *result_px_ptr = reinterpret_cast<u8*>(RX_PX_BUFFER_BASE);
    *result_px_ptr = 0;

    tx_done_px = 0;
    rx_done_px = 0;
    error_px = 0;

    tx_done_wt = 0;
    error_wt = 0;

    // Flush the buffers before the DMA transfer, in case the Data Cache is enabled
    Xil_DCacheFlushRange(reinterpret_cast<UINTPTR>(tx_buffer_px), sizeof(u8) * 5 * 128);
    Xil_DCacheFlushRange(reinterpret_cast<UINTPTR>(tx_buffer_wt), sizeof(u8) * 5 * 128);
    Xil_DCacheFlushRange(reinterpret_cast<UINTPTR>(result_ptr_px), sizeof(u8) * 10 * 128);

#ifdef ACC_INTERFACE_DBG
    xil_printf("MemInterface GetTime start\r\n");
#endif

    XTime start_time;
    XTime_GetTime(&start_time);

    status = XAxiDma_SimpleTransfer(&axi_dma_px, reinterpret_cast<UINTPTR>(result_ptr_px), sizeof(u8) * 10 * 128,
                                    XAXIDMA_DEVICE_TO_DMA);

    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("rx_buffer transfer was not successful for pixels %d\r\n", status);
#endif
        struct MemResult res = {
            true,  // error
            0,     // time_ns
            0,     // length
            0,     // result
        };

        return res;
    }

    status = XAxiDma_SimpleTransfer(&axi_dma_px, reinterpret_cast<UINTPTR>(tx_buffer_px), sizeof(u8) * 5 * 128,
                                    XAXIDMA_DMA_TO_DEVICE);

    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("tx_buffer transfer Pixels was not successful %d\r\n", status);
#endif
        struct MemResult res = {
            true,  // error
            0,     // time_ns
            0,     // length
            0,     // result
        };

        return res;
    }

    status = XAxiDma_SimpleTransfer(&axi_dma_wt, reinterpret_cast<UINTPTR>(tx_buffer_wt), sizeof(u8) * 5 * 128,
                                    XAXIDMA_DMA_TO_DEVICE);

    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("tx_buffer transfer Weights was not successful %d\r\n", status);
#endif
        struct MemResult res = {
            true,  // error
            0,     // time_ns
            0,     // length
            0,     // result
        };

        return res;
    }

    status = Xil_WaitForEventSet(POLL_TIMEOUT_COUNTER, NUMBER_OF_EVENTS, &error);
    if (status == XST_SUCCESS) {
        if (!tx_done_px || !tx_done_wt) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("Transmit error %d\r\n", status);
#endif
        } else if (status == XST_SUCCESS && !rx_done_px) {
#ifdef ACC_INTERFACE_DBG
            xil_printf("Receive error %d\r\n", status);
#endif
        }

        struct MemResult res = {
            true,  // error
            0,     // time_ns
            0,     // length
            0,     // result
        };

        return res;
    }

    // Wait for TX of weights done or time_out
    status = Xil_WaitForEventSet(POLL_TIMEOUT_COUNTER, NUMBER_OF_EVENTS, &tx_done_wt);
    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Transmit failed for Weights %d\r\n", status);
#endif
        struct MemResult res = {
            true,  // error
            0,     // time_ns
            0,     // length
            0,     // result
        };

        return res;
    }

    // Wait for TX of Pixels done or time_out
    status = Xil_WaitForEventSet(POLL_TIMEOUT_COUNTER, NUMBER_OF_EVENTS, &tx_done_px);
    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Transmit failed for Pixels %d\r\n", status);
#endif
        struct MemResult res = {
            true,  // error
            0,     // time_ns
            0,     // length
            0,     // result
        };

        return res;
    }

    // Wait for RX done or time_out
    status = Xil_WaitForEventSet(POLL_TIMEOUT_COUNTER, NUMBER_OF_EVENTS, &rx_done_px);
    if (status != XST_SUCCESS) {
#ifdef ACC_INTERFACE_DBG
        xil_printf("Receive failed %d\r\n", status);
#endif

        struct MemResult res = {
            true,  // error
            0,     // time_ns
            0,     // length
            0,     // result
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
        sizeof(u8) * 10 * 128,  // length
        result_ptr_px           // result
    };

    return res;
}

MemInterface::~MemInterface() {
    disable_intr_system(&intc, DMA0_TX_INTR_ID, DMA0_RX_INTR_ID);
    disable_intr_system(&intc, 0xFFFF, DMA1_RX_INTR_ID);
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
        if (axi_dm_inst == &axi_dma_wt) {
            MemInterface::instance.error_wt = 1;
        } 
        else {
            MemInterface::instance.error_px = 1;
        }
        

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
        if (axi_dm_inst == &axi_dma_wt) {
            MemInterface::instance.tx_done_wt = 1;
        } 
        else {
            MemInterface::instance.tx_done_px = 1;
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
        MemInterface::instance.error_px = 1;

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
#ifdef ACC_INTERFACE_DBG
        xil_printf("MemInterface GetTime end\r\n");
#endif

        // Get time in two steps because of volatile qualifier of end_time
        XTime tmp;
        XTime_GetTime(&tmp);
        MemInterface::instance.end_time = tmp;

        MemInterface::instance.rx_done_px = 1;
    }
}

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
static int setup_intr_system(INTC *IntcInstancePtr, XAxiDma *AxiDmaPtr, u16 TxIntrId, u16 RxIntrId) {
    int status;

    XScuGic_Config *IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (!IntcConfig) return XST_FAILURE;

    status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig, IntcConfig->CpuBaseAddress);
    if (status != XST_SUCCESS) return XST_FAILURE;

    if (TxIntrId != 0xFFFF) {
        status = XScuGic_Connect(IntcInstancePtr, TxIntrId,
                                 (Xil_InterruptHandler)tx_intr_handler, AxiDmaPtr);
        if (status != XST_SUCCESS) return status;
        XScuGic_Enable(IntcInstancePtr, TxIntrId);
    }

    status = XScuGic_Connect(IntcInstancePtr, RxIntrId,
                             (Xil_InterruptHandler)rx_intr_handler, AxiDmaPtr);
    if (status != XST_SUCCESS) return status;
    XScuGic_Enable(IntcInstancePtr, RxIntrId);

    // Initialize exceptions and register top-level handler
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
static void disable_intr_system(INTC *IntcInstancePtr, u16 TxIntrId, u16 RxIntrId) {
    if (TxIntrId != 0xFFFF) XScuGic_Disconnect(IntcInstancePtr, TxIntrId);
    XScuGic_Disconnect(IntcInstancePtr, RxIntrId);
}
