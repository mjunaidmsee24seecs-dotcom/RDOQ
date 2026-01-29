//==============================================================================  
// Module: scan_pattern_generator_top  
// Description: Top-level HEVC scan pattern generator  
//==============================================================================  

module scan_pattern_generator_top (  
    // Global signals  
    input  logic        clk,  
    input  logic        rst_n,  
      
    // Control signals  
    input  logic        start,  
    output logic        done,  
      
    // Input parameters  
    input  logic [2:0]  log2BlockWidth,   // 2=4x4, 3=8x8, 4=16x16, 5=32x32  
    input  logic [2:0]  log2BlockHeight,  // 2=4x4, 3=8x8, 4=16x16, 5=32x32  
    input  logic [1:0]  scanType,         // 0=diag, 1=hor, 2=ver  
      
    // Output scan arrays  
    output logic [9:0]  scanIndex,        // Current scan position (0-31)  
    output logic [9:0]  scanAddr,         // Raster address at scan position  
    output logic [9:0]  scanCGAddr,       // Coefficient group address  
    output logic        scanValid         // Valid output flag  
);  

    // Wire declarations
    logic [9:0] scan_position;
    logic update_position;
    logic scan_complete;
    
    // ROM outputs
    logic [4:0] rom_4x4_data;
    logic [6:0] rom_8x8_data;
    logic [8:0] rom_16x16_data;
    logic [9:0] rom_32x32_data;
    logic [4:0] cg_rom_data;
    
    // ROM address/control signals
    logic [4:0] rom_4x4_addr;
    logic [5:0] rom_8x8_addr;
    logic [7:0] rom_16x16_addr;
    logic [9:0] rom_32x32_addr;
    logic [1:0] rom_4x4_scan_type;
    logic [1:0] rom_8x8_scan_type;
    logic [1:0] rom_16x16_scan_type;
    logic [1:0] rom_32x32_scan_type;
    
    // Coefficient group signals
    logic [1:0] log2WidthInGroups;
    logic [1:0] log2HeightInGroups;
    logic [5:0] cg_position;
    
    //==========================================================================
    // Module Instantiations
    //==========================================================================
    
    // ROM modules
    rom_4x4_patterns u_rom_4x4 (
        .scan_type(rom_4x4_scan_type),
        .address(rom_4x4_addr),
        .data(rom_4x4_data)
    );
    
    rom_8x8_patterns u_rom_8x8 (
        .scan_type(rom_8x8_scan_type),
        .address(rom_8x8_addr),
        .data(rom_8x8_data)
    );
    
    rom_16x16_patterns u_rom_16x16 (
        .scan_type(rom_16x16_scan_type),
        .address(rom_16x16_addr),
        .data(rom_16x16_data)
    );
    
    rom_32x32_patterns u_rom_32x32 (
        .scan_type(rom_32x32_scan_type),
        .address(rom_32x32_addr),
        .data(rom_32x32_data)
    );
    
    // Coefficient group ROM
    rom_coefficient_groups u_rom_cg (
        .log2WidthInGroups(log2WidthInGroups),
        .log2HeightInGroups(log2HeightInGroups),
        .address(cg_position),
        .data(cg_rom_data)
    );
    
    // ROM MUX Controller
    rom_mux_controller u_rom_mux (
        .log2BlockWidth(log2BlockWidth),
        .log2BlockHeight(log2BlockHeight),
        .scanType(scanType),
        .scanPosition(scan_position),
        .rom_4x4_data(rom_4x4_data),
        .rom_8x8_data(rom_8x8_data),
        .rom_16x16_data(rom_16x16_data),
        .rom_32x32_data(rom_32x32_data),
        .scanAddress(scanAddr),
        .rom_4x4_addr(rom_4x4_addr),
        .rom_8x8_addr(rom_8x8_addr),
        .rom_16x16_addr(rom_16x16_addr),
        .rom_32x32_addr(rom_32x32_addr),
        .rom_4x4_scan_type(rom_4x4_scan_type),
        .rom_8x8_scan_type(rom_8x8_scan_type),
        .rom_16x16_scan_type(rom_16x16_scan_type),
        .rom_32x32_scan_type(rom_32x32_scan_type)
    );
    
    // Main Controller FSM
scan_controller_fsm u_controller_fsm (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .log2BlockWidth(log2BlockWidth),
    .log2BlockHeight(log2BlockHeight),
    .scanType(scanType),
    .scan_valid(scanValid),
    .done(done),
    .scan_position(scan_position),
    .update_position(update_position)
);

    //==========================================================================
    // Output Logic and Calculations
    //==========================================================================
    
    // Coefficient group calculations
    assign log2WidthInGroups = (log2BlockWidth >= 2) ? log2BlockWidth - 2 : 0;
    assign log2HeightInGroups = (log2BlockHeight >= 2) ? log2BlockHeight - 2 : 0;
    assign cg_position = scan_position >> 4;  // Divide by 16 (4x4 group size)
    
    // Output assignments
    assign scanIndex = scan_position;  // Lower bits for index
    assign scanCGAddr = cg_rom_data;
    
    // Scan complete detection
 assign scan_complete = (scan_position >= ((1 << log2BlockWidth) * (1 << log2BlockHeight) - 1));


endmodule