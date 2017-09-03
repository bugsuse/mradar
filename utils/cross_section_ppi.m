function [itpprod, itpheight, itplon, itplat] = cross_section_ppi(radar, interp, varargin)
%    确定剖面线后将雷达所有仰角PPI扫描数据插值到任意剖面
% 
%       输入参数：
%       --------------------
%          radar : 包含雷达产品的结构体数组. 关于 radar 结构体变量的数据结构可查看
%                  read_sradar 函数说明
%         interp : 指定剖面方式，为字符型变量。
%                'se'  : 表示可以选定起始坐标和终点坐标，用于指定剖面线。
%                    'stapos' : 起始坐标点，二元素向量。分别为x和y的起始点，
%                               第一个值为x的起始点，第二个值为y的起始点。
%                    'endpos' : 终点坐标，二元素向量。分别为x和y的终点，
%                               第一个值为x的终点，第二个值为y的终点。
%                'md'  : 表示可以通过指定中点坐标和倾斜角度选择剖面线。
%                    'midpos' : 中点坐标，二元素向量。
%                               第一个值为x的中点坐标，第二个值为y的中点坐标。
%                    'angle'  : 用于指定倾斜角度，即直线斜率。 默认值为45度。
%                               取值范围应在 -90 到 90 之间。
%                  两种选择剖面线的模式都有一个 步长 参数，用于控制水平插值的间隔。
%                  'horspace'  :  用于控制插值的间隔，即网格密度。默认值为 0.1
%                           一般情况下采用默认值即可，当所选的网格数较少时可以
%                           适当减小此值，但应保证大于0，否则会报错。
%                     ！！！ 注意 ！！！
%                         当使用默认值效果不好或报错时，应减小此值！
%       'verspace'  :  浮点数
%                  用于控制剖面垂直方向的插值间隔，值为1时不进行插值. 如果要对垂直方向
%                  插值，此值需小于1
%      'method' ： 插值方法.  字符串变量
%                支持的插值方法包括： 'linear', 'nearest', 'cubic'
%                默认值为 'nearest'
%     
%        输出参数：
%       ------------------
%           itpprod    ： 所选剖面产品数据
%           itpheight  ： 对应剖面的高度
%           itplon     ： 剖面线格点化后的经度网格
%           itplat     ： 剖面线格点化后的纬度网格
%
%    绘图时使用 itpheight, itplon(或 itplat)，itpprod
%% 示例：
%   示例1
%   step = 0.01;
%   itpstep = 0.001;
%   se = ginput(2);
%   stapos = se(1, :);
%   endpos = se(2, :);
%   
%   interp = 'se'; 
%   [itpprod, itpheight, itplon, itplat] = cross_section_ppi(radar, interp, 'stapos', stapos, 'endpos', endpos, 'hor', step, 'ver', itpstep, 'method', 'nearest');
%
%   示例2
%   interp = 'md';
%   angle = 45;
%   midpos = ginput(1);
%   [itpprod, itpheight, itplon, itplat] = cross_section_ppi(radar, interp, 'midpos', midpos, 'angle', angle, 'hor', step, 'ver', itpstep, 'method', 'cubic');
%%

p = inputParser;
validVard = @(x) isstruct(x);
validAngle = @(x) isnumeric(x) && x >= -90 && x <= 90;
validValue = @(x) isvector(x) && min(x) >=0 && ~isempty(x);
validHorVer = @(x) isnumeric(x) && length(x) == 1 && x > 0;
validMethod = @(x) ismember(x, {'linear', 'nearest', 'cubic'});
defaultAngle = 45;   % 默认剖面角度
defaultHor = 0.1;
defaultVer = 0.1;
defaultMethod = 'nearest';
addRequired(p, 'radar', validVard)
addRequired(p, 'interp', @isstr)
addParameter(p, 'stapos', validValue)
addParameter(p, 'endpos', validValue)
addParameter(p, 'midpos', validValue)
addParameter(p, 'angle', defaultAngle, validAngle)
addParameter(p, 'horspace', defaultHor, validHorVer)
addParameter(p, 'verspace', defaultVer, validHorVer)
addParameter(p, 'method', defaultMethod, validMethod);
parse(p, radar, interp, varargin{:})

step = p.Results.horspace;
itpstep = p.Results.verspace;
method = p.Results.method;

lat = radar.coordinate.elevation(1).latitude.data;
lon = radar.coordinate.elevation(1).longitude.data;
prod = radar.products.elevation(1).data;
phinum = double(radar.info.elenum);

if strcmp(p.Results.interp, 'se')
    stapos = p.Results.stapos;
    endpos = p.Results.endpos;
    x = stapos(1):step:endpos(1);
    y = ((endpos(2)-stapos(2))/(endpos(1)-stapos(1))).*(x - endpos(1)) + endpos(2);
elseif strcmp(p.Results.interp, 'md')
    midpos = p.Results.midpos;
    xmin = min(min(lon));
    xmax = max(max(lat));
    x = [xmin:step:midpos(1), midpos(1)+step:step:xmax];
    y = tan((angle*3.1415926)/180)*(x - midpos(1)) + midpos(2);
end

cross = zeros(length(x), phinum);
height = zeros(length(x), phinum);

distance = deg2km(sqrt((y - radar.info.latitude.data).^2 + (x - radar.info.longitude.data).^2));

cross(:, 1) = griddata(lat, lon, prod, y, x, method);
height(:, 1) = distance*tan(radar.products.elevation(1).elevation*3.1415926/180);

for i = 2:phinum
    lat1 = radar.coordinate.elevation(i).latitude.data;
    lon1 = radar.coordinate.elevation(i).longitude.data;
    prod1 = radar.products.elevation(i).data;
    
    cross(:, i) = griddata(lat1, lon1, prod1, y, x, method);
    height(:, i) = distance*tan(radar.products.elevation(i).elevation*3.1415926/180);
end

height = height + radar.info.height.data/1000;

horind = 1:length(x);
verind = 1:phinum;
[horgrid, vergrid] = ndgrid(horind, verind);
%  插值
itpverind = 1:itpstep:phinum; 
[itphorgrid, itpvergrid] = ndgrid(horind, itpverind);
itpheight = griddata(horgrid, vergrid, height, itphorgrid, itpvergrid);

itplon = repmat(x, length(itpverind), 1)';
itplat = repmat(y, length(itpverind), 1)';
itpprod = griddata(horgrid, height, cross, itphorgrid, itpheight);

org_mean_height = mean(mean(diff(height, 1, 2)));
itp_mean_height = mean(mean(diff(itpheight, 1, 2)));

fprintf('高度方向由平均 %.4f km 插值到平均 %.4f km！\n', org_mean_height, itp_mean_height);
end
