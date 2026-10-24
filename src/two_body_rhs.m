function derivative = two_body_rhs(~, state, gravitationalParameter)
%TWO_BODY_RHS Planar two-body equations of motion.

position = state(1:2);
velocity = state(3:4);
radius = norm(position);

acceleration = -gravitationalParameter * position / radius^3;
derivative = [velocity; acceleration];
end

