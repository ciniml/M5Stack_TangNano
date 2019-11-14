/*
 * @file top.sv
 * @brief M5Stack Tang Nano top module
 */
// Copyright 2019 Kenta IDA
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module top (
    input wire clock,
    input wire resetn,

    output wire led_r,
    output wire led_g,
    output wire led_b,

    inout wire sda,
    inout wire scl 
);

logic [6:0] reg_address;
logic reg_is_write;
logic reg_request;
logic reg_response;
logic [7:0] reg_read_data;
logic [7:0] reg_write_data;

i2c_slave #(.I2C_FILTER_DEPTH(2)) i2c_slave_inst (
    .reset(!resetn),
    .*
);

logic [2:0] led_out;
assign led_r = !led_out[0];
assign led_g = !led_out[1];
assign led_b = !led_out[2];

always @(posedge clock) begin
    if( !resetn ) begin
        led_out <= 0;
    end
    else begin
        reg_response <= 0;
        if( reg_request && reg_is_write ) begin
            reg_response <= 1;
            case(reg_address)
                8'h01: led_out <= reg_write_data[2:0];
                default: reg_response <= 0;
            endcase
        end
        else if( reg_request && !reg_is_write ) begin
            reg_response <= 1;
            case(reg_address)
                8'h00: reg_read_data = 8'ha5;
                8'h01: reg_read_data = {5'b0, led_out};
                default: reg_response <= 0;
            endcase
        end
    end
end

endmodule
    
