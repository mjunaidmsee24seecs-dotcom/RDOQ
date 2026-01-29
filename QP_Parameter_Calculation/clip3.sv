module clip3 #(
parameter int MIN_VAL = -52,
parameter int MAX_VAL = 57
)(
input  logic signed [15:0] x,
output logic signed [15:0] y
);
always_comb begin
if (x < MIN_VAL)
y = MIN_VAL;
else if (x > MAX_VAL)
y = MAX_VAL;
else
y = x;
end
endmodule