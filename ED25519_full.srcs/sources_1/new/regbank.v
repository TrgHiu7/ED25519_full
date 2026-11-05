`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 08:13:32 AM
// Design Name: 
// Module Name: regbank
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module regbank(
    input  wire                 clk,
    input  wire                 rst_n,         // Reset để tải P, d, px, py, pz
    input  wire                 we,          // Ghi dữ liệu vào dst_sel
    input  wire [4:0] dst_sel, src1_sel, src2_sel,      // Chỉ số ghi, Chỉ số đọc operand 1, Chỉ số đọc operand 2
    input  wire [255:0]        din,          // Dữ liệu ghi
    input  wire [255:0]        px,py,pz,pt,   // P1(X, Y, Z, T)
    input wire [255:0] bx,by,bz,bt,
    input  wire          load_b,       // Pulse when ECPA starts: latch B in one cycle
    
    output wire [255:0]        src1_out, src2_out,    // Dữ liệu operand 1, Dữ liệu operand 2
    output wire [255:0]        qx, qy, qz, qt   // Điểm đầu ra Q(X, Y, Z, T)
);
    // Bộ nhớ thanh ghi
    reg [255:0] reg_array [0:31];
    // Hằng số Ed25519
    localparam [255:0] d_2 = 256'h2406d9dc56dffce7198e80f2eef3d13000e0149a8283b156ebd69b9426b2f159;
    // Reset hoặc nạp dữ liệu đầu vào
    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                reg_array[i] <= 256'd0;
       
            reg_array[3]  <= px;
            reg_array[4]  <= py;
            reg_array[5]  <= pz;
            reg_array[15] <= pt;
        
            reg_array[25] <= d_2;
            reg_array[26] <= 256'd2;
        end else begin
            // ECPA reads the second point from these fixed addresses.
            // Re-load them for EACH addition, not only on reset.
            if (load_b) begin
                reg_array[3]  <= bx;
                reg_array[4]  <= by;
                reg_array[5]  <= bz;
                reg_array[15] <= bt;
            end

            if (we)
                reg_array[dst_sel] <= din;
        end
    end
    // Đọc song song
    assign src1_out = reg_array[src1_sel];
    assign src2_out = reg_array[src2_sel];
    // Đầu ra Q(X, Y, Z) được giả định ở vị trí cố định
    assign qx = reg_array[22];
    assign qy = reg_array[23];
    assign qz = reg_array[24];
    assign qt = reg_array[27];
endmodule
