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
    XAxiDma axi_dma_wt;
    XAxiDma axi_dma_px;             

    INTC intc;


    XAxiDma_Config *config_wt;
    XAxiDma_Config *config_px;

    MemInterface();

   public:
    // Flags interrupt handlers use to notify the application context the events.
    volatile u32 tx_done_wt;
    volatile u32 error_wt;

    volatile u32 tx_done_px;
    volatile u32 rx_done_px;
    volatile u32 error_px;
    volatile XTime end_time;

    static MemInterface instance;

    ~MemInterface();
    MemInterface(MemInterface &other) = delete;
    void operator=(const MemInterface &) = delete;

    struct MemResult run(u8 *tx_buffer_wt, u8 *tx_buffer_px) {
};
