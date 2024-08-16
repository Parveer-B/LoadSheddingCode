function [sortedbuses] = powerflowthroughbuses(mpc,removedbuses,cutlines)
%Get initial sequence for RAD func sorted by power flow through buses
%Run the DCOPF on the total mpc, with the inital generator costs. Sort the
%buses by the power flow through each one decreasingly after running that sim. Return that
%sequence as an IC for the RAD algo (or something else later maybe)


mpc.bus = [mpc.bus; removedbuses]; %add the previously removed buses
mpc.branch = [mpc.branch; cutlines];
mpc = ext2int(mpc);
define_constants;

resultss = dcopf(mpc);
buslist = removedbuses(:, 1);

flows = arrayfun(@(x) resultss.bus(find(resultss.bus(:, BUS_I) == x), PD) + sum(max(resultss.branch(resultss.branch(:, 1) == x, PF), 0)) + sum(max(resultss.branch(resultss.branch(:, 2) == x, PT), 0)), buslist);
[~, order] = sort(flows, 'descend');
%flowsthrough = arrayfun(@(x, y) struct('id', x, 'flow', y), buslist, flows);
sortedbuses = buslist(order);




end