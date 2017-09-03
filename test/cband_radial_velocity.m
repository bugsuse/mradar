clear,clc

dbstop if error
tic

filename = 'E:\MATLAB\radar\NUIST.20140928.070704.AR2';
       
% 读取径向速度
radar = read_cradar(filename, 3);     

toc       
lat = radar.coordinate.elevation(1).latitude.data;
lon = radar.coordinate.elevation(1).longitude.data;
height1 = radar.coordinate.elevation(1).height.data;
prod = radar.products.elevation(1).data;

pcolor(lon, lat, prod)
axis square        %  保持绘图框为正方形
shading flat       %  去除图形网格线
cid = colorbar;

se = ginput(2);

stapos = se(1, :);
endpos = se(2, :);

interp = 'se';

method = 'nearest';

step = 0.01; % 控制经度数据插值
itpstep = 0.01; % 控制高度插值间隔

[itpprod, itpheight, itplon, itplat] = cross_section_ppi(radar, interp, 'stapos', stapos, 'endpos', endpos, 'hor', step, 'ver', itpstep, 'method', 'nearest');

figure
%axis([min(min(dist)) max(max(dist)) 0 20])
pcolor(itplon, itpheight, itpprod)
ylabel('Height (km)')
ylim([0, 20])
axis square        %  保持绘图框为正方形
shading flat       %  去除图形网格线
cid = colorbar;
