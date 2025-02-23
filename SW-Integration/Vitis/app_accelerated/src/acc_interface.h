#pragma once

#include <iterator>

#include "xaxidma.h"
#include "xil_types.h"
#include "xiltimer.h"

struct AccResult {
    bool error;
    u64 time_ns;
    u8 result;
};

class AccInterface {
   private:
    XAxiDma axi_dma;  // Instance of the XAxiDma
#ifndef SDT
    INTC intc;  // Instance of the Interrupt Controller
#endif

    XAxiDma_Config *config;

    AccInterface();

   public:
    // Flags interrupt handlers use to notify the application context the events.
    volatile u32 tx_done;
    volatile u32 rx_done;
    volatile u32 error;
    volatile XTime end_time;

    static AccInterface instance;

    ~AccInterface();
    AccInterface(AccInterface &other) = delete;
    void operator=(const AccInterface &) = delete;

    struct AccResult run(u8 *tx_buffer, int length);
};
