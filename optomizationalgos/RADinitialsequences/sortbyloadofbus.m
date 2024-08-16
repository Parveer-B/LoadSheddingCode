function [sortedbuses] = sortbyloadofbus(~,removedbuses,cutlines)
%Get initial sequence for RAD func sorted by amount of load. Tiebreaker is
%speed of restoration
%Sort the buses by amount of load. Return that
%sequence as an IC for the RAD algo (or something else later maybe)



define_constants;

buslist = removedbuses(:, 1);

normflows = arrayfun(@(x) (removedbuses(removedbuses(:, BUS_I) == x, PD)) + 0.001/(size(cutlines(cutlines(:, T_BUS) == x, :), 1) + size(cutlines(cutlines(:, F_BUS) == x, :), 1)), buslist);
[~, order] = sort(normflows, 'descend');
%flowsthrough = arrayfun(@(x, y) struct('id', x, 'flow', y), buslist, flows);
sortedbuses = buslist(order);




end