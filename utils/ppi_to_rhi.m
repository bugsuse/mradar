function [prod, height, lon, lat] = ppi_to_rhi(radar, azimu)
%% 寻找与给定方位角最近的方位角数据，提取出所有仰角数据
%   只寻找与给定方位角最近的方位角数据，不进行插值
%
%   输入参数：
%       radar  ：  包括的雷达产品数据以及其它信息.  结构体
%       azimu  ：  方位角.  浮点数标量
%   输出参数：
%       prod   ： 提取到的产品数据
%       height ： 提取到的产品数据对应的高度信息
%       lon    ： 方位角对应的经度信息
%       lat    ： 方位角对应的纬度信息
%  注意：
%     绘图时使用 lon(或lat)，height，prod，以上输出变量均已网格化
%%
phinum = radar.info.elenum;

for i = 1:phinum
    azimuth = radar.coordinate.elevation(1).azimuth.data;

    [~, k] = min(abs(azimuth - azimu));

    nea_ind = unique(k);

    if nea_ind > 1
        near_ind = nea_ind(1);
    else
        near_ind = nea_ind;
    end

    if  i == 1
        lon1 = radar.coordinate.elevation(1).longitude.data(near_ind, :);
        lat1 = radar.coordinate.elevation(1).latitude.data(near_ind, :);
        height1 = radar.coordinate.elevation(1).height.data(near_ind, :);
        [~, s2] = size(radar.products.elevation(1).data);
        prod = zeros(s2, phinum);
        height = prod;
        prod(:, 1) = radar.products.elevation(1).data(near_ind, :);
        height(:, 1) = height1;
    else
    
    lon2 = radar.coordinate.elevation(i).longitude.data;
    lat2 = radar.coordinate.elevation(i).latitude.data;
    height2 = radar.coordinate.elevation(i).height.data;
    prodc = radar.products.elevation(i).data;
    prod(:, i) = griddata(lon2, lat2, prodc, lon1, lat1);
    height(:, i) = griddata(lon2, lat2, height2, lon1, lat1);    
    end
end

lon = repmat(lon1', phinum, 1);
lat = repmat(lat1', phinum, 1);

end