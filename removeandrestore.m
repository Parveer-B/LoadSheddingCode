function [outputstruct, equalcosts] = removeandrestore(mpc, set_buses, buses_to_remove, algoinputs)
%basically does 06-04-busremovalandrestoration for me


%remove buses here
define_constants;
cutlines = [];
removedbuses = [];
rng('shuffle')
if set_buses

    for i=1:size(buses_to_remove, 2)
        rowtoremove = find(mpc.bus(:,1) == buses_to_remove(i));
    
    
        %cut the lines
        %check if branch contains bus. if so cut the line and add the line to
        %the cutlines array
        cutlines = [cutlines; mpc.branch(mpc.branch(:, F_BUS) == buses_to_remove(i) | mpc.branch(:, T_BUS) == buses_to_remove(i), :)];
        mpc.branch(mpc.branch(:, F_BUS) == buses_to_remove(i) | mpc.branch(:, T_BUS)== buses_to_remove(i), :) = [];
        
        %remove the knocked out bus
        removedbuses = [removedbuses; mpc.bus(rowtoremove,:)];
        mpc.bus(rowtoremove,:) = [];      
    end 
else
    for i=1:buses_to_remove
        if i==1
            %remove a random bus
            numbuses = size(mpc.bus, 1);
            rowtoremove = randi(numbuses,1); %get the removed row
            toremoveid = mpc.bus(rowtoremove, BUS_I); %get the ID of the removed row
        else
            numcutlines = size(cutlines, 1);
            while true
                %if not the first bus, travel to a bus adjacent to a knock out
                %one, knocking it out as well
                stormtravelline = randi(numcutlines,1);
                bus1 = cutlines(stormtravelline,1);
                bus2 = cutlines(stormtravelline,2);
                if ~ismember(removedbuses(:,1), bus1)
                    toremoveid = bus1;
                    rowtoremove = find(mpc.bus(:,1) == toremoveid);
                    break 
                elseif ~ismember(removedbuses(:,1), bus2)
                    toremoveid = bus2;
                    rowtoremove = find(mpc.bus(:,1) == toremoveid);
                    break
                end
            end
        end
    
    
        %cut the lines
        %check if branch contains bus. if so cut the line and add the line to
        %the cutlines array
        cutlines = [cutlines; mpc.branch(mpc.branch(:, F_BUS) == toremoveid | mpc.branch(:, T_BUS) == toremoveid, :)];
        mpc.branch(mpc.branch(:, F_BUS) == toremoveid | mpc.branch(:, T_BUS)== toremoveid, :) = [];
        
        %remove the knocked out bus
        removedbuses = [removedbuses; mpc.bus(rowtoremove,:)];
        mpc.bus(rowtoremove,:) = [];      
    end 
end
   

%islanding = py.importlib.import_module('islanding'); %just used in BELUGA
branchespy = py.numpy.array(mpc.branch(:,1:2));
buslist = py.numpy.array(mpc.bus(:,1));
islanding = py.islanding.test_islanding(branchespy, buslist);
islands = reshape(cell(islanding), [size(islanding, 2), 1]);



for i=1:size(islands,1)
   cq = cell(islands{i,1});
   islands{i,1} = [cq{:}]; %converting python stuff to matlab stuff
end

%After this section, we have removed all the buses and seperated everything
%into islands

%Now we need to split our cases based on the islands
cases = struct;
for i=1:size(islands,1)
    sim = getislandmpc(mpc,islands{i});
    cases(i).params = sim;
end


%get results here

results = struct;
for i=1:size(islands,1)
    resulti = addloadshedding(cases(i).params);
    results(i).result = resulti;
end

%Get Total Load Shed

totalshed = 0;
for i=1:size(islands,1)
    resultt = results(i).result.x;
    numbuses = size(results(i).result.bus,1);
    totalshed = totalshed + 100*sum(resultt(end-numbuses+1:end));
end

totalknockedout = sum(removedbuses(:,PD));

totalloss = totalshed + totalknockedout;


%Do bus restoration here
outputstruct = repmat(struct('allseq', [], 'seq', [], 'cost', 0, 'time', 0), size(algoinputs, 1), 1);
for i = 1:size(algoinputs, 1)
    tic
    [allsequences, bestsequence, cost] = algoinputs(i).function(algoinputs(i).value, mpc, removedbuses, cutlines, totalloss);
    outputstruct(i).time = toc;
    outputstruct(i).allseq = allsequences;
    outputstruct(i).seq = bestsequence;
    outputstruct(i).cost = cost;
end
costs = [outputstruct(:).cost];
equalcosts = ((max(costs) - min(costs)) > 1e-9);
% tic
% [allsequences1, bestsequence1, cost1] = ngreedywrestorebsdmockcost(1, mpc, removedbuses, cutlines, totalloss);
% time1 = toc;
% tic
% [allsequences2, bestsequence2, cost2] = keepnwrestorebsdmockcost(5, mpc, removedbuses, cutlines, totalloss);
% time2 = toc;
% tic
% [allsequences3, bestsequence3, cost3] = closecostwrestorebsdmockcost(0.01, mpc, removedbuses, cutlines, totalloss);
% time3 = toc;
% 
% diff = isequal(bestsequence1,bestsequence2, bestsequence3);
% 
% outputstruct = struct('allseq1', [] , 'seq1', bestsequence1, 'cost1', cost1, 'time1', time1, 'allseq2', [], 'seq2', bestsequence2, 'cost2', cost2, 'time2', time2, 'allseq3', [], 'seq3', bestsequence3, 'cost3', cost3, 'time3', time3, 'diff', diff);
% outputstruct(1).allseq1 = allsequences1;
% outputstruct(1).allseq2 = allsequences2;
% outputstruct(1).allseq3 = allsequences3;
end