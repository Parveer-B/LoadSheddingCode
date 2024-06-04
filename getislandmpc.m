function sim = getislandmpc(sim, island)
define_constants;
arbgen = [1	72.3 27.03 300 -300	1.04 100 1 0 0 0 0 0 0 0 0 0 0 0 0 0]; %arbitrary generator with no power output

%create a new "case" for the island with only nodes and lines which are
%part of the island
sim.branch = sim.branch((ismember(sim.branch(:, F_BUS), island)) | (ismember(sim.branch(:, T_BUS), island)), :);
sim.bus = sim.bus(ismember(sim.bus(:, BUS_I), island),:);
sim.gen = sim.gen(ismember(sim.gen(:, GEN_BUS), island),:);

%add a "generator" with no power output if the system doesn't have one
if size(sim.gen, 1) == 0
    sim.gen(1,:) = arbgen;
    sim.gen(1,1) = sim.bus(1,1); %assign the "generator" to the first bus
    sim.bus(1,2) = 3;

%check if there is no slack bus
elseif ~ismember(3, sim.bus(:, BUS_TYPE))
    busindex = sim.gen(1,1); %just assign the first bus with a generator as the slack bus
    busesinisland = sim.bus(:, 1);
    sim.bus(find(busesinisland == busindex), 2) = 3; %actually assigning as a slack bus
end

%just set number of rows of gencost to be the number of generators. This will
%avoid errors (even though gencost isn't actually used)
sim.gencost = sim.gencost(1: size(sim.gen, 1), :);