function result = addloadshedding(mpc)
%basically run the stuff in 05-28-cs9rmvbus.mlx
define_constants;
mpc = ext2int(mpc);

% Create the optimization model object
om = opf_setup(mpc, mpoption('model', 'DC'));

%add the load shedding variable
om = om.add_var('loadshed', size(mpc.bus, 1), zeros(size(mpc.bus, 1), 1), zeros(size(mpc.bus, 1), 1), mpc.bus(:, PD)/mpc.baseMVA, 'C');

%get negative identity matrix for loadshed variables 
negI = -1*eye(size(mpc.bus, 1));

om.lin.data.vs.Pmis(3).name = 'loadshed';
om.lin.data.vs.Pmis(3).idx = {};
om.lin.data.A.Pmis = [om.lin.data.A.Pmis negI];

%editing cost function here
if isfield(om.var.data.v0, 'y')
    om.qdc.data.vs.pwl(1).name = 'loadshed';
    om.qdc.data.Q.pwl = zeros(size(mpc.bus, 1));
    om.qdc.data.c.pwl = ones(size(mpc.bus, 1), 1);
    om.qdc.data.k.pwl = 0;
    om.qdc.N = size(mpc.bus, 1);
    om.qdc.idx.iN.pwl = size(mpc.bus, 1);
    om.qdc.idx.N.pwl = size(mpc.bus, 1);
else
    om.qdc.data.vs.polPg(1).name = 'loadshed';
    om.qdc.data.Q.polPg = zeros(size(mpc.bus, 1));
    om.qdc.data.c.polPg = ones(size(mpc.bus, 1), 1);
    om.qdc.data.k.polPg = 0;
    om.qdc.N = size(mpc.bus, 1);
    om.qdc.idx.iN.polPg = size(mpc.bus, 1);
    om.qdc.idx.N.polPg = size(mpc.bus, 1);
end

result = dcopf_solver(om, mpoption('verbose', 0, 'opf.dc.solver', 'OT'));



result.bus(:,3) = result.bus(:,3) - result.baseMVA*result.x((end - size(mpc.bus, 1) + 1):end);
end
