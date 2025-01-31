function totalloss = busremovalforproftaeyong(casefile,loadscaling, buses_to_remove)
%Get totalloss caused by removal of buses
%Inputs a case file, load scaling and removed buses. Removes those buses
%from the case and splits case into islands if necessary. Then runs those
%cases and calculates total load shed. We add that to the knocked out load
%to find the total amount of load which is out.

define_constants;
mpc = loadcase(casefile); %load the case file
mpc = scale_load(loadscaling, mpc); %increase the load demand by a factor (1.2
%hawaii, 1.25 texas, 2.4 case9)

removedbuses = [];
for i=1:size(buses_to_remove, 2)
    rowtoremove = find(mpc.bus(:,1) == buses_to_remove(i));


    %cut the lines
    %check if branch contains bus. if so cut the line
    mpc.branch(mpc.branch(:, F_BUS) == buses_to_remove(i) | mpc.branch(:, T_BUS)== buses_to_remove(i), :) = [];
    %remove the knocked out bus
    removedbuses = [removedbuses; mpc.bus(rowtoremove,:)];
    mpc.bus(rowtoremove,:) = [];      
end 

branches = mpc.branch(:, 1:2);        
buslist = mpc.bus(:, 1); 
islanding = test_islanding(branches, buslist);
islands = reshape(cell(islanding), [size(islanding, 2), 1]);

%old python stuff that doens't work anymore
% branchespy = py.numpy.array(mpc.branch(:,1:2));
% buslist = py.numpy.array(mpc.bus(:,1));
% islanding = py.islanding.test_islanding(branchespy, buslist);
% islands = reshape(cell(islanding), [size(islanding, 2), 1]);
% 
% for i=1:size(islands,1)
%    cq = cell(islands{i,1});
%    islands{i,1} = [cq{:}]; %converting python stuff to matlab stuff
% end

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

end