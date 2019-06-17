function radar = read_sradar(filename, types, longitude, latitude, height)
%%   读取SA/SB格式雷达数据
%  
%       输入参数
%       -----------------
%        filename   :  SA/SB 雷达文件.   字符串变量  
%          types    :  雷达产品.    整型变量
%                      1   :  reflectivity
%                      2   :  radial velocity
%                      3   :  spectral width
%         longitude :  雷达站点经度
%         latitude  :  雷达站点纬度
%          height   :  雷达站点高度，单位：m
%
%      输出参数
%     -------------------
%        radar  : 包括雷达产品数据，经纬度坐标，高度，方位角，仰角等信息
%          .type. :  struct
%% radar 数据结构
%                                                     | data
%                                      | elevation(1) | eleva
%               | products | elevation |   ...           ...
%               |                      | elevation(n) | data
%               |                                     | eleva
%               |                                                  | data
%               |                                       | longitude| units
%         radar |                        |              | latitude | 同上
%               |                        | elevation(1) | height   | 
%               |                        |              | azimuth
%               |                        |              | elevation
%               | coordinate | elevation | ....
%               |                        |
%               |                        |              | longitude
%               |                        |              | latitude
%               |                        | elevation(n) | height
%               |                  | data               | azimuth
%               |      | longitude | units              | elevation
%               | info | latitude  | 同上
%                      | height    | 同上
%                      | elenum  
%% 示例
%  注意：当不知道经纬度和高度时，可设置为0，但在使用 cross_section_ppi 时 雷达站点
%  的经纬度是必须的
%  
%   types = 1;
%   radar = read_sradar(filename, types, lon, lat, 0);
%%
fid = fopen(filename);
data = fread(fid, 'uint8');

num = 2432;
data = reshape(data, [num, length(data)/num])';

vcp = unique(data(:, 73) + data(:, 74)*256);
if length(vcp) ~= 1
    error('VCP model error!')
end

if vcp == 11
    phi = [0.50, 0.50, 1.45, 1.45, 2.40, 3.35, 4.30, 5.25, ...
        6.2, 7.5, 8.7, 10, 12, 14, 16.7, 19.5];
elseif vcp == 21
    phi = [0.50, 0.50, 1.45, 1.45, 2.40, 3.35, 4.30, 6.00, ...
        9.00, 14.6, 19.5];
elseif vcp == 31
    phi = [0.50, 0.50, 1.50, 1.50, 2.50, 2.50, 3.50, 4.50];
elseif vcp == 32
    phi = [0.50, 0.50, 2.50, 3.50, 4.50];
end

elev_num = data(:, 45) + data(:, 46)*256;

unphi = unique(phi);
phinum = length(unphi);
radar = struct();

for i = 1:phinum    
    eleva = unphi(i);

    phiidx = find(phi == eleva);
    pnum = length(phiidx);

    if pnum == 2
        if types == 2 || types == 3
            phiidx = phiidx(2);
        elseif types == 1
            phiidx = phiidx(1); 
        end
    end
   
    eleidx = find(elev_num == phiidx);
    if length(eleidx) <= 2
        error('The number of radial is wrong!')
    else
        eleidse = eleidx(1):eleidx(end);
    end   
    radar = get_prod(radar, data, i, types, eleidse, eleva, longitude, latitude);   
end
radar.info.longitude.data = longitude;
radar.info.longitude.units = 'degree';
radar.info.latitude.data = latitude;
radar.info.latitude.units = 'degree';
radar.info.height.data = height;
radar.info.height.units = 'm';
radar.info.elenum = phinum;
end

function [prod, lat, lon, height, llunits, azimu, eleva] = get_data(data, eleidse, dnum, distance, start, longitude, latitude)   
    amu = (data(eleidse, 37) + data(eleidse, 38)*256)/8*180/4096;
    amusize = length(amu);
    azimu = repmat(amu, 1, dnum);
    elevation = (data(eleidse, 43) + data(eleidse, 44)*256)/8*180/4096;
    eleva = repmat(elevation, 1, dnum);        
    r = ((1:dnum) - 0.5)*distance; 
    r = repmat(r, amusize, 1);

    [lat, lon, height] = sph2cart(deg2rad(azimu), deg2rad(eleva), r);
    llunits = 'km';
    prod = data(eleidse, start:dnum + start - 1);

    if ~isempty(longitude) || ~isempty(latitude)
       lon =  km2deg(lon) + longitude;
       lat = km2deg(lat) + latitude;
       llunits = 'degree';
    end
end

function radar = get_prod(radar, data, i, types, eleidse, eleva, longitude, latitude)

if types == 1
    start = 129;
    ray_nums = unique(data(eleidse, 55) + data(eleidse, 56)*256);
    distance = unique(data(eleidse, 51) + data(eleidse, 52)*256)/1000;
    ray_nums_all = unique(data(eleidse, 55) + data(eleidse, 56)*256);
    [prod, lat, lon, height, llunits, azimuths, elevations] = get_data(data, eleidse, ray_nums, distance, start, longitude, latitude);
    prod = (prod - 2)/2 - 32;
elseif types == 2
    start = 129;    % start byte 
    ray_nums = unique(data(eleidse, 55) + data(eleidse, 56)*256); % max length
    distance = unique(data(eleidse, 53) + data(eleidse, 54)*256)/1000;
    ray_nums_all = unique(data(eleidse, 57) + data(eleidse, 58)*256);
    res = unique(data(:, 71) + data(:, 72)*256);
    if res == 2
        [prod, lat, lon, height, llunits, azimuths, elevations] = get_data(data, eleidse, ray_nums, distance, start, longitude, latitude);
        prod = (prod - 2)/2 - 63.5;
    elseif res == 4
        [prod, lat, lon, height, llunits, azimuths, elevations] = get_data(data, eleidse, ray_nums, distance, start, longitude, latitude);
        prod =  (prod - 2) - 127;
    else
        error('Error! velocity mode is reading %d, but should reading 2 or 4.', res);
    end
elseif types == 3
    start = 1049;
    ray_nums = unique(data(eleidse, 55) + data(eleidse, 56)*256);
    distance = unique(data(eleidse, 53) + data(eleidse, 54)*256)/1000;
    ray_nums_all = unique(data(eleidse, 57) + data(eleidse, 58)*256);
    [prod, lat, lon, height, llunits, azimuths, elevations] = get_data(data, eleidse, ray_nums, distance, start, longitude, latitude);
    prod = (prod -2)/2 - 63.5;
end

if ray_nums_all == 0
    radar.products.elevation(i).data = NaN;
    radar.products.elevation(i).elevation = eleva;
else
    radar.products.elevation(i).data = prod;
    radar.products.elevation(i).elevation = eleva;
    radar.coordinate.elevation(i).longitude.data = lon;
    radar.coordinate.elevation(i).longitude.units = llunits;
    radar.coordinate.elevation(i).latitude.data = lat;
    radar.coordinate.elevation(i).latitude.units = llunits;
    radar.coordinate.elevation(i).height.data = height;
    radar.coordinate.elevation(i).height.units = 'km';
    radar.coordinate.elevation(i).elevation.data = elevations;
    radar.coordinate.elevation(i).elevation.units = 'degree';
    radar.coordinate.elevation(i).elevation.description = 'elevation for radar sweep';
    radar.coordinate.elevation(i).azimuth.data = azimuths;
    radar.coordinate.elevation(i).azimuth.units = 'degree';
    radar.coordinate.elevation(i).azimuth.description = 'azimuth for per elevation radar sweep';
end
end
