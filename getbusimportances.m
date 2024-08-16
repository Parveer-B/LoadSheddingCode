fid = fopen('casess.csv', 'rt');
mpc = loadcase('case9.m');
outages = textscan(fid, '%s', 'Delimiter', '\n'); %load outages as a cell array
fclose(fid); 
outages = outages{1};
numbuses = size(mpc.bus, 1);
numcases = size(outages, 1);
outputinfo = struct('allseq', [], 'seq', [], 'cost', 0, 'time', 0);
datastruct = repmat(struct('totalcase', outputinfo, 'caseminusbus', 0), numcases, 1);
indivbusweight = zeros(numbuses, 1);
for i = 1:numcases
    casee = str2num(outages{i});
    numbusesincase = size(casee, 2);
    [totalcase, ~] = removeandrestore(mpc, true, casee, struct('function', @keepx, 'value', numbusesincase));
    totalcasecost = totalcase.cost;
    if isnan(totalcasecost)
        continue
    end
    datastruct(i).totalcase = totalcase;
    if numbusesincase == 1
        caseminusbus = struct();
        caseminusbus.indivcase = 0;
        caseminusbus.busprefixed = casee;
        caseminusbus.diffcost = totalcasecost;
        datastruct(i).caseminusbus = caseminusbus;
        continue
    end
    caseminusbus = repmat(struct('indivcase', outputinfo, 'busprefixed', 0, 'diffcost', 0), numbusesincase , 1);
    for j = 1:numbusesincase
        busid = casee(j);
        dividedcase = casee;
        dividedcase(j) = [];
        [divcaseres, ~] = removeandrestore(mpc, true, dividedcase, struct('function', @keepx, 'value', numbusesincase - 1));
        divcasecost = divcaseres.cost;
        caseminusbus(j).indivcase = divcaseres;
        caseminusbus(j).busprefixed = busid;
        diffcost = totalcasecost - divcasecost;
        caseminusbus(j).diffcost = diffcost;

        indivbusweight(busid) = indivbusweight(busid) + diffcost;


    end
    datastruct(i).caseminusbus = caseminusbus;

end


normalizedbusweight = indivbusweight/numcases;