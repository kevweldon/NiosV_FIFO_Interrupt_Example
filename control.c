#include <stdio.h>
#include "system.h"
#include "sys/alt_irq.h"
#include "altera_avalon_fifo_regs.h"
#include "altera_avalon_fifo_util.h"

// Number of words defined to create one packet
#define PACKET_SIZE 4
// Define FIFO thresholds
#define ALMOST_EMPTY 16
#define ALMOST_FULL 4

static int init_fifo(void);
static void handle_fifo_interrupt(void *, alt_u32);

int main() {

  printf("\nEntering control loop.\n");
  init_fifo();
  while (1) {
  }
  
  return 0;
}

// Handle FIFO interrupt
static void handle_fifo_interrupt(void* context, alt_u32 id) {
  int fifo_level;
  int fifo_read_data;
  int write_address;
  
  // Cast context to fifo_irq_event's type. It is important
  // to declare this volatile to avoid unwanted compiler optimization.
  volatile int* fifo_irq_event_ptr = (volatile int*) context;

  // Store the value in the FIFO's irq register in *context.
  *fifo_irq_event_ptr = altera_avalon_fifo_read_event(COMMAND_FIFO_IN_CSR_BASE,
						      ALTERA_AVALON_FIFO_EVENT_ALL);
  
  printf("Interrupt Occured at address: %#x\n", COMMAND_FIFO_IN_CSR_BASE);
  // Read FIFO level
  fifo_level = altera_avalon_fifo_read_level(COMMAND_FIFO_IN_CSR_BASE);
  while (fifo_level > PACKET_SIZE-1) {
    //printf("FIFO level = %u\n", fifo_level);
    if (fifo_level > (PACKET_SIZE-1)) {
      printf("FIFO has complete packet\n");
      for (int i=0; i<PACKET_SIZE; i++) {
	altera_avalon_read_fifo(COMMAND_FIFO_OUT_BASE, COMMAND_FIFO_IN_CSR_BASE, &fifo_read_data);
	printf("Read from FIFO: %#x\n", fifo_read_data);
	// Since the first word of our four word packet is defined to be the destination
	// address, we need to store it.
	if (i==0) {
	  write_address = fifo_read_data;
	} else {
	  // Now we write the rest of the packet to the address we captured
	  IOWR_32DIRECT(write_address+((i-1)*4), 0, fifo_read_data);
	}
      }
    }
  fifo_level = altera_avalon_fifo_read_level(COMMAND_FIFO_IN_CSR_BASE);
  }

  // Reset the FIFO's IRQ register.
  altera_avalon_fifo_clear_event(COMMAND_FIFO_IN_CSR_BASE,
				 ALTERA_AVALON_FIFO_EVENT_ALL);
}


// Initialize the FIFO
static int init_fifo() {
  int return_code = ALTERA_AVALON_FIFO_OK;
  
  volatile int fifo_irq_event;
  
  // Define interrupt pointer to match the alt_ic_isr_register() prototype.
  void* fifo_irq_event_ptr = (void*) &fifo_irq_event;

  // Clear event register, set desired interrupts,
  // set almost empty and almost full thresholds
  return_code = altera_avalon_fifo_init(COMMAND_FIFO_IN_CSR_BASE,
					4, // enable almost_full interrupt
					ALMOST_EMPTY,
					ALMOST_FULL);

#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
  alt_ic_isr_register(COMMAND_FIFO_IN_CSR_IRQ_INTERRUPT_CONTROLLER_ID,
 		      COMMAND_FIFO_IN_CSR_IRQ,
 		      (alt_isr_func) handle_fifo_interrupt,
 		      fifo_irq_event_ptr,
 		      0);
#else  
  alt_irq_register( COMMAND_FIFO_IN_CSR_IRQ,
		    fifo_irq_event_ptr, handle_fifo_interrupt );
#endif
  return return_code;
}
