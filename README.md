# Superscalar Processor Design (Out-of-Order)

This repository contains the implementation of an out-of-order superscalar processor designed as part of the EE739: Processor Design course project at IIT Bombay. The project focuses on a 2-way fetch superscalar processor with a 16-bit architecture, featuring key components such as register renaming, reservation stations, reorder buffers to optimize performance .

## Key Features
- **2-Way Fetch Superscalar Architecture**: Fetches and processes two instructions per cycle.
- **16-bit Processor**: Operates with 8 registers (R0-R7) and a 16-bit instruction set.
- **Pipeline Stages**: Includes Instruction Fetch, Decode, Dispatch, Reservation Station, Execute, Completion, and Write Back.
- **Core Elements**: Implements register renaming, reservation stations, and reorder buffers.
- **Instruction Set**: Supports R-type (Register-Register), I-type (Immediate), and J-type (Jump) instructions.

## Repository Structure
- **Verilog Files**: Contains the Verilog code for the processor components, including instruction fetch, decode, reservation station, and more.
- **Documentation**: Includes the project report (`EE739_Project.pdf`) detailing the design and implementation.
