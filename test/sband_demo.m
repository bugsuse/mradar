clear,clc

dbstop if error

collev = [ 255,255,255; 0,236,236; 0,160,246; 0,0,246; 0,255,0; ...
           0,200,0; 0,144,0; 255,255,0; 231,192,0; 255,0,0; ...
           214,0,0; 192,0,0; 255,0,255; 153,85,201 ]/255.;
       
filename = 'data/Z_RADR_I_Z9515_20160623063100_O_DOR_SA_CAP.bin';

types = 1; % �� eleva = 0.5���� dupe = false ʱ��ֻ�з���������
lon = 120.2011;
lat = 33.4311; % �״ﾭγ������

radar = read_sradar(filename, types, lon, lat, 24.3);

lat = radar.coordinate.elevation(1).latitude.data;
lon = radar.coordinate.elevation(1).longitude.data;
height1 = radar.coordinate.elevation(1).height.data;
prod = radar.products.elevation(1).data;
phinum = radar.info.elenum;

% -33 ��ʾ�޻ز���-32.5��ʾ����ģ��
prod(prod <= -32.5) = NaN;

figure
pcolor(lon, lat, prod)
axis square        %  ���ֻ�ͼ��Ϊ������
shading flat       %  ȥ��ͼ��������
cid = colorbar;
caxis([0, 70])
%   set grid line style for colorbar to solid line
%   set(cid, 'YGrid', 'on', 'GridLineStyle', '-');
xlim([119.3, 120.5])
ylim([33.4, 34.6])
colormap(collev);

se = ginput(2);

%se = [119.7520   33.6601;
%      120.0182   33.8739];

stapos = se(1, :);
endpos = se(2, :);

interp = 'se';

method = 'nearest';

types = 1;
step = 0.001; % ���ƾ������ݲ�ֵ
itpstep = 0.001; % ���Ƹ߶Ȳ�ֵ���

[itpprod, itpheight, itplon, itplat] = cross_section_ppi(radar, interp, 'stapos', stapos, 'endpos', endpos, 'hor', step, 'ver', itpstep, 'method', 'nearest');

figure
pcolor(itplon, itpheight, itpprod)
ylabel('Height (km)')
ylim([0, 20])
%axis square        %  ���ֻ�ͼ��Ϊ������
shading flat       %  ȥ��ͼ��������
cid = colorbar;
caxis([0, 70])
colormap(collev);

%% ppi to rhi
azimu = 314;
[prod, height, lon, lat] = ppi_to_rhi(radar, azimu);
ylim([0, 20])
%axis square        %  ���ֻ�ͼ��Ϊ������
shading flat       %  ȥ��ͼ��������
cid = colorbar;
caxis([0, 70])
colormap(collev);
