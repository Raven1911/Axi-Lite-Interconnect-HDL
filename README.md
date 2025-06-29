# Axi-Lite-Interconnect-HDL

# I. Introduction
> IP AXI Lite Interconnect core connects ONE or THREE AXI memory-mapped master devices to ONE or MORE memory-mapped slave devices. The AXI interfaces conform to the AMBA® AXI version 4 specification from ARM®.

# II. Features
> * The Master Interface (MI) can be configured to comprise 1-3 MI slots to issue 
transactions to up to 16 connected slave devices.
> * The Slave Interface (SI) of the core can be configured to comprise 1-16 SI slots to accept transactions from up to 
3 connected master devices.
> * Split Write Transaction and Read Transaction channels separately
> * 32-bit address width
> * Interface data widths: 32 bits.
> * Fixed priority, time quantum(avoid deadlock) and round-robin arbitration.
