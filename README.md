# Axi-Lite-Interconnect-HDL

# I. Introduction
> IP AXI Lite Interconnect core connects ONE or THREE AXI memory-mapped master devices to ONE or MORE memory-mapped slave devices. The AXI interfaces conform to the AMBA® AXI version 4 specification from ARM®.

# II. Features
> * The Master Interface (MI) can be configured to comprise 1-3 MI slots to issue 
transactions to up to 16 connected slave devices.
> * The Slave Interface (SI) of the core can be configured to comprise 1-16 SI slots to accept transactions from up to 
3 connected master devices.
> * Split Write Transaction and Read Transaction channels separately
> * Address width: 32 to 64 bits.
> * Interface data widths: 32 bits.
> * Fixed priority, time quantum(avoid deadlock) and round-robin arbitration.

# III. Overview
> * AXI is an interface specification that defines the interface of IP blocks, rather than the interconnect 
itself. The following diagram shows how AXI is used to interface an interconnect component:
> ![alt text](docs/axi1.png)

> * AXI in a multi-master system:
> ![alt text](docs/axi2.png)

> * AXI channels - The AXI specification describes a point-to-point protocol between two interfaces: a master and a 
slave. The following diagram shows the five main channels that each AXI interface uses for communication:  
> ![alt text](docs/axi3.png)
> Write operations use the following channels: 
> * * The master sends an address on the Write Address (AW) channel and transfers data on the Write 
Data (W) channel to the slave.   