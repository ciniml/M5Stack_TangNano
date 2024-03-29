/**
 * @file ws2812b.sv
 * @brief control signal generator for Worldsemi WS2812B and variants.
 */
// Copyright 2019 Kenta IDA
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module ws2812b #(
    parameter longint CLOCK_HZ = 24_000_000,
    parameter NUMBER_OF_LEDS = 16,
    localparam NUMBER_OF_REGS = 4,
    localparam I2C_REG_ADDRESS_WIDTH = $clog2(NUMBER_OF_REGS)
) (
    input wire clock,
    input wire resetn,

    output logic serial_out,

    input wire [I2C_REG_ADDRESS_WIDTH-1:0] reg_address,
    input wire reg_is_write,
    input wire reg_request,
    output reg reg_response,
    output reg [7:0] reg_read_data,
    input wire [7:0] reg_write_data
);

localparam longint LONG_PERIOD  = (580*CLOCK_HZ + 1000_000_000-1)/1000_000_000;
localparam longint SHORT_PERIOD = (220*CLOCK_HZ + 1000_000_000-1)/1000_000_000;
localparam longint RESET_PERIOD = (280_000*CLOCK_HZ + 1000_000_000-1)/1000_000_000;

typedef struct packed {
    bit [7:0] g;
    bit [7:0] r;
    bit [7:0] b;
} pixel_t;

pixel_t pixels[NUMBER_OF_LEDS-1:0]; /* synthesis syn_ramstyle="block_ram" */

typedef bit [$clog2(NUMBER_OF_LEDS) - 1:0] led_index_t;
led_index_t led_index;
pixel_t  led_pixel_buffer;
localparam REG_COMMAND = 0;
localparam REG_B       = 1;
localparam REG_G       = 2;
localparam REG_R       = 3;

always @(posedge clock) begin
    if( !resetn ) begin
        led_index <= 0;
    end
    else begin
        reg_response <= 0;
        if( reg_request ) begin
            if( reg_is_write ) begin
                case(reg_address)
                REG_COMMAND: begin
                    led_index <= reg_write_data;
                    led_pixel_buffer <= pixels[led_index];
                end
                REG_R: begin led_pixel_buffer.r <= reg_write_data; pixels[led_index] <= '{r: reg_write_data, g: led_pixel_buffer.g, b: led_pixel_buffer.b}; end
                REG_G: begin led_pixel_buffer.g <= reg_write_data; pixels[led_index] <= '{r: led_pixel_buffer.r, g: reg_write_data, b: led_pixel_buffer.b}; end
                REG_B: begin led_pixel_buffer.b <= reg_write_data; pixels[led_index] <= '{r: led_pixel_buffer.r, g: led_pixel_buffer.g, b: reg_write_data}; end
                endcase
            end
            else begin
                case(reg_address)
                REG_COMMAND: begin
                    reg_read_data <= led_index;
                end
                REG_R: reg_read_data <= led_pixel_buffer.r;
                REG_G: reg_read_data <= led_pixel_buffer.g;
                REG_B: reg_read_data <= led_pixel_buffer.b;
                endcase
            end
            reg_response <= 1;
        end
    end
end

localparam PERIOD_COUNTER_BITS = $clog2(RESET_PERIOD); 
localparam LED_COUNTER_BITS = $clog2(NUMBER_OF_LEDS);

logic [PERIOD_COUNTER_BITS-1:0] period_counter;
logic [4:0] bit_counter;
logic [LED_COUNTER_BITS-1:0] led_counter;
logic [23:0] pixel;

enum {IDLE, INTERVAL, RESET, BEGIN_LED, BEGIN_BIT, BIT_HIGH, BIT_LOW } state;

always_comb begin
    case(state)
    RESET: serial_out = 0;
    BIT_LOW: serial_out = 0;
    default: serial_out = 1;
    endcase
end

always @(posedge clock) begin
    if( !resetn ) begin
        state <= IDLE;
        pixel <= 0;
    end
    else begin
        case(state)
        IDLE: begin
            period_counter <= LONG_PERIOD+SHORT_PERIOD;
            led_counter <= 0;
            state <= INTERVAL;
        end
        INTERVAL: begin
            period_counter <= period_counter - 1;
            if( period_counter == 0 ) begin
                state <= RESET;
            end
        end
        RESET: begin
            period_counter <= period_counter - 1;
            if( period_counter == 0 ) begin
                state <= BEGIN_LED;
            end
        end
        BEGIN_LED: begin
            bit_counter <= 23;
            pixel <= pixels[led_counter];
            state <= BEGIN_BIT;
        end
        BEGIN_BIT: begin
            period_counter <= pixel[bit_counter] ? LONG_PERIOD : SHORT_PERIOD;
            state <= BIT_HIGH;
        end
        BIT_HIGH: begin
            period_counter <= period_counter - 1;
            if( period_counter == 0 ) begin
                period_counter <= pixel[bit_counter] ? SHORT_PERIOD : LONG_PERIOD;
                state <= BIT_LOW;
            end
        end
        BIT_LOW: begin
            period_counter <= period_counter - 1;
            if( period_counter == 0 ) begin
                bit_counter <= bit_counter - 1;
                if( bit_counter == 0 ) begin
                    led_counter <= led_counter + 1;
                    if( led_counter == NUMBER_OF_LEDS - 1 ) begin
                        state <= IDLE;
                    end
                    else begin
                        state <= BEGIN_LED;
                    end
                end
                else begin
                    state <= BEGIN_BIT;
                end
            end
        end
        endcase
    end
end

endmodule
    
