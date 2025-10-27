#pragma once

#include "xaxidma.h"
#include "xil_types.h"
#include "xiltimer.h"

struct MemResult {
    bool error;
    u64 time_ns;
    size_t result_length;
    u8 *result;
};

class MemInterface {
    
   private:             

    XAxiDma_Config *config_wt;
    XAxiDma_Config *config_px;

    MemInterface();

   public:
    XAxiDma axi_dma_wt;
    XAxiDma axi_dma_px;

    // Flags interrupt handlers use to notify the application context the events.
    volatile u32 cfg_done;
    volatile u32 tx_wt_done;
    volatile u32 tx_px_done;
    volatile u32 rx_done;
    volatile XTime end_time;

    volatile u32 error;

    static MemInterface instance;

    volatile u32 tx_wt_iteration;
    volatile u32 tx_px_iteration;
    volatile u32 rx_iteration;

    ~MemInterface();
    MemInterface(MemInterface &other) = delete;
    void operator=(const MemInterface &) = delete;

    struct MemResult run(u8 *tx_buffer_wt, u8 *tx_buffer_px);
};
