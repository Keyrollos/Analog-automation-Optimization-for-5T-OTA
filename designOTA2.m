%OTA Synthesis Function
function OTA = designOTA2(specs)
%Additional Specs
VDD = 1.8;

%load LUTs
load 180nch.mat;
load 180pch.mat;
GBW=specs.GBW;
while (1)
%Input Pair
OTA.M1.gm = GBW * specs.CL * 2 * pi;
% assume ro(load) = 5 * ro(input) --> ro(input) = 6/5 R_total
DC_Gain_mag = 10^(specs.AVDC / 20); % Convert from dB to mag 
Rout = DC_Gain_mag / OTA.M1.gm; % Compute the equivalent output resistance of OTA (Rout)

OTA.M1.ro = (6/5)*Rout; % Complete the line to compute the ro of M1

OTA.M1.gds = 1 / OTA.M1.ro;
OTA.M1.VDS = VDD/3;
OTA.M1.VSB = 0;
OTA.M1.gm_gds = OTA.M1.gm / OTA.M1.gds;
OTA.M1.gm_ID = 15; % assumption
OTA.M1.ID = OTA.M1.gm / OTA.M1.gm_ID % Complete the line to get the current of M1


% Search for the minimum L that gives gm / gds > specified value
L_vector = nch.L;
gm_gds_vector = look_up(nch, 'GM_GDS', 'GM_ID', OTA.M1.gm_ID, 'VDS', OTA.M1.VDS, 'L', L_vector);
OTA.M1.L = min(L_vector(gm_gds_vector >= OTA.M1.gm_gds)); %Complete the line to get the minimum L that gives gm/gds >= OTA.M1.gm_gds
% Compute ID/W to get the W value
OTA.M1.ID_W = look_up(nch, 'ID_W', 'GM_ID', OTA.M1.gm_ID, 'VDS', OTA.M1.VDS, 'L', OTA.M1.L);
OTA.M1.W = OTA.M1.ID / OTA.M1.ID_W;

%CM_Load
OTA.M3.ID = OTA.M1.ID;
OTA.M3.ro = 5 * OTA.M1.ro; %Complete the line to get the ro of the CM load
OTA.M3.VSB = 0;
OTA.M3.gds = 1 / OTA.M3.ro;
OTA.M3.VDS = VDD/3;
OTA.M3.gm_ID = 10;
OTA.M3.gm = OTA.M3.gm_ID * OTA.M3.ID;
OTA.M3.gm_gds = OTA.M3.gm / OTA.M3.gds;
gm_gds_vector = look_up(pch, 'GM_GDS', 'GM_ID', OTA.M3.gm_ID, 'VDS', OTA.M3.VDS, 'L', L_vector);
OTA.M3.L = min(L_vector(gm_gds_vector > OTA.M3.gm_gds));
OTA.M3.ID_W = look_up(pch, 'ID_W', 'GM_ID', OTA.M3.gm_ID, 'VDS', OTA.M3.VDS, 'L', OTA.M3.L); %Complete the line to get the ID/W of M3
OTA.M3.W = OTA.M3.ID/OTA.M3.ID_W;
OTA.M3.gm_gds_vector=gm_gds_vector;
% Tail bias
OTA.M5.L = 1; %assumption
OTA.M5.ID = 2 * OTA.M1.ID;
OTA.M5.VSB = 0;
OTA.M5.VDS = VDD/3;
OTA.M5.gm_ID = 10; %assumption
% Get ID/W to compute W
OTA.M5.ID_W = look_up(nch, 'ID_W', 'GM_ID', OTA.M5.gm_ID, 'VDS', OTA.M5.VDS, 'L', OTA.M5.L);
OTA.M5.W = OTA.M5.ID / OTA.M5.ID_W;

% get CMIN bias value
OTA.M1.VGS =look_upVGS(nch, 'GM_ID', OTA.M1.gm_ID, 'VDS', OTA.M1.VDS, 'VSB', OTA.M1.VSB, 'L', OTA.M1.L); %Complete the line to get the VGS of M1
OTA.M3.VGS =look_upVGS(pch, 'GM_ID', OTA.M3.gm_ID, 'VDS', OTA.M3.VDS, 'VSB', OTA.M3.VSB, 'L', OTA.M3.L); %Complete the line to get the VGS of M3
OTA.M1.VG = OTA.M1.VGS + OTA.M5.VDS %Complete the line to get the DC CM input of OTA
CDD_N=look_up(nch, 'CDD', 'VDS', OTA.M1.VDS, 'VSB', 0, 'L',OTA.M1.L,'VGS',OTA.M1.VGS)*((OTA.M1.W));
CDD_P=look_up(pch, 'CDD', 'VDS', OTA.M3.VDS, 'VSB', 0, 'L',OTA.M3.L,'VGS',OTA.M3.VGS)*((OTA.M3.W));
CGD_N=look_up(nch, 'CGD', 'VDS', OTA.M1.VDS, 'VSB', 0, 'L',OTA.M1.L,'VGS',OTA.M1.VGS)*((OTA.M1.W)/(nch.W));
CGD_P=look_up(pch, 'CGD', 'VDS', OTA.M3.VDS, 'VSB', 0, 'L',OTA.M3.L,'VGS',OTA.M3.VGS)*((OTA.M3.W)/(pch.W));

% GBW_NEW
OTA.GBW_New = OTA.M1.gm / (2*pi*(specs.CL + CDD_N + CDD_P + CGD_N + CGD_P));
Condition = ((specs.GBW - OTA.GBW_New )/specs.GBW);
    if abs(Condition) <= 0.001
     break
    else  GBW=GBW*(1+Condition);
    end
end
