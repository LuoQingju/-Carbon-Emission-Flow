%% ̼�ŷ��� Carbon Emission Flow (CEF)

% �������ġ�����ϵͳ̼�ŷ����ļ��㷽����̽��[1]��
% [1] �����,������,��Ǭҫ,��.����ϵͳ̼�ŷ����ļ��㷽����̽[J].����ϵͳ�Զ���,2012,36(11):44-49.

% ���ߣ������
% ���䣺luoqingju@qq.com
% ��������ѧ����ѧԺ
% �ۺ��ǻ���Դϵͳ�Ż�����������Ŷ� ISESOOC ��˼��

% ������ MATPOWER https://matpower.org/

% ����ˮƽ���ޣ�������д��󼰲���֮���������������ָ����

clc
clear

define_constants; % MATPOWER��Defines useful constants for indexing data

mpc = case14;

Pg = [120 40 60 19 20]'; % ���÷�����й�����
mpc.gen(:, PG) = Pg; % �޸�MATPOWER�����ķ�����й�����

mpopt = mpoption('verbose', 0, 'out.all', 0); % MATPOWER������ӡ������
res = rundcpf(mpc, mpopt); % MATPOWER������ֱ������
if res.success ~= 1
    error('----------ֱ����������ʧ�ܣ�----------')
end

N = size(res.bus, 1); % �ڵ�����ĸ������
K = size(res.gen, 1); % �������

Pd = res.bus(:, PD); % �ڵ㸺��
gen_bus = res.gen(:, GEN_BUS); % ������ڵ�

fbus = res.branch(:, F_BUS); % ��· "from" �˽ڵ�
tbus = res.branch(:, T_BUS); % ��· "to" �˽ڵ�

Pl_from = res.branch(:, PF); % ��· "from" �˹���
Pl_to = res.branch(:, PT); % ��· "to" �˹���

Pl_from(Pl_from < 0) = 0; % ����Ĺ�������
Pl_to(Pl_to < 0) = 0; % ����Ĺ�������

idx_PF = Pl_from > 0; % ��· "from" �˹�������
PB_F_Mat = sparse(fbus(idx_PF), tbus(idx_PF), Pl_from(idx_PF), N, N); % ��· "from" �˳����ֲ�����

idx_PT = Pl_to > 0; % ��· "to" �˹�������
PB_T_Mat = sparse(tbus(idx_PT), fbus(idx_PT), Pl_to(idx_PT), N, N); % ��· "to" �˳����ֲ�����

% ֧·�����ֲ�����(branch power flow distribution matrix) N �׷���
PB_Mat = PB_F_Mat + PB_T_Mat;

% ����ע��ֲ�����(power injection distribution matrix) K��N �׾���
PG_Mat = sparse(1:K, gen_bus, Pg, K, N);

% ���ɷֲ�����(load distribution matrix) M��N �׾��� M Ϊ������
% Ϊ�˼򻯣�����ÿ���ڵ㶼���ڸ��ɣ������ڸ��ɵĽڵ㰴�ո���Ϊ�㴦��
% ���ԣ����ɷֲ������Ϊ N��N �׾���
PL_Mat = sparse(1:N, 1:N, Pd, N, N);

PZ_Mat = [PB_Mat; PG_Mat];

% �ڵ��й�ͨ������(nodal active power flux matrix) N �׶Խ���
PN_Mat = sparse(1:N, 1:N, ones(1, N+K)*PZ_Mat, N, N); % �����еĹ�ʽ2

% �������̼�ŷ�ǿ������(unit carbon emission intensity vector)
EG_Vec = [875 525 0 520 0]'; % % �����еĹ�ʽ14

% �ڵ�̼������(nodal carbon intensity vector)
EN_Vec = (PN_Mat - PB_Mat') \ (PG_Mat' * EG_Vec);  % �����еĹ�ʽ13

% ֧·̼���ʷֲ����� (branch carbon emission flow rate distribution matrix) N �׷���
% �����еĹ�ʽ5���ܴ��ڱ���Ӧ���� RB = diag(EN)*PB
RB_Mat = sparse(1:N, 1:N, EN_Vec, N, N) * PB_Mat;
RB_Mat = RB_Mat./1000; % kgCO2/h ==> tCO2/h

% ����̼��������(load carbon emission rate vector)
RL_Vec = PL_Mat * EN_Vec; % �����еĹ�ʽ7
RL_Vec = RL_Vec./1000; % kgCO2/h ==> tCO2/h

% ֧·̼���ܶ�(branch carbon emission flow intensity)
EB_Mat = sparse(1:N, 1:N, EN_Vec, N, N) * spones(PB_Mat);

% ����ע��̼����
IN_Vec = PG_Mat' * EG_Vec;
IN_Vec = IN_Vec./1000; % kgCO2/h ==> tCO2/h

%% ������

L = size(res.branch, 1); % ��·��
Pl = res.branch(:, PF); % ��·����
EB_Vec = zeros(L, 1); % ֧·̼���ܶ�
RB_Vec = zeros(L, 1); % ֧·̼����
for i = 1:L
    if Pl(i) > 0
        EB_Vec(i) = EB_Mat(fbus(i), tbus(i));
        RB_Vec(i) = RB_Mat(fbus(i), tbus(i));
    else
        EB_Vec(i) = EB_Mat(tbus(i), fbus(i));
        RB_Vec(i) = RB_Mat(tbus(i), fbus(i));
    end
end

Table2 = [(1:N)', full(diag(PN_Mat)), EN_Vec]; % �����еı�2
Table3 = [fbus, tbus, Pl, EB_Vec, RB_Vec]; % �����еı�3
Table4 = [(1:N)', RL_Vec, IN_Vec]; % �����еı�4

fprintf('\n')
disp('��2 �ڵ��й�ͨ����ڵ�̼��')
disp('�ڵ�    �ڵ��й�ͨ��(MW)    �ڵ�̼��(gCO2/kWh)')
disp(Table2)
fprintf('\n')

fprintf('\n')
disp('��3 ֧·�й�������̼����')
disp('��ʼ�ڵ�    ��ֹ�ڵ�    ֧·�й�����(MW)    ֧·̼���ܶ�(gCO2/kWh)    ̼����(tCO2/h)')
disp(Table3)
fprintf('\n')

fprintf('\n')
disp('��4 ����̼���ʺͻ���ע��̼����')
disp('�ڵ�    ����̼����(tCO2/h)    ����ע��̼����(tCO2/h)')
disp(Table4)
fprintf('\n')