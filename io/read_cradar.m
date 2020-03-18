function radar = read_cradar(filename, Moment_Number)
%%  处理南信大 C 波段双偏振多普勒雷达数据，默认输出所有仰角的某一产品输出 
% 输入参数：
%     filename  ： 文件名.  字符串
%     Moment_Number ： 要读取的产品.  整数.
%            可能的取值，具体可查阅手册
%             1   :  dBT   Total Reflectivity, without clutter removed
%             2   :  dBZ   Reflectivity after clutter removed
%             3   :   V    Mean Radial Velocity
%             4   :   W    Spectrum Width
%             5   :  SQI   Signal Quality Index
%             7   :  ZDR   Differential Reflectivity
%             9   :   CC   Cross Correlation Coefficient
%             10  : ΦDP   Differential Phase
%             11  :  KDP   Specific Differential Phase
%             16  :  Zc    reflectivity corrected
%     输出参数：
%       radar  ：  包含指定产品的所有仰角数据以及一些其它信息. 结构体
%      
%%
fid = fopen(filename, 'rb');
fseek(fid,32,'bof');

%1.2.读取128个字节的SITE CONFIG
BaseData.Common.Site.Code =  fread(fid,8,'uint8=>char')';    %Site Code  in characters
BaseData.Common.Site.Name =  fread(fid,32,'uint8=>char')';    %Site Name or  description  in characters
BaseData.Common.Site.Latitude =  double(fread(fid,1,'*float32'));   % Latitude of Radar Site 雷达站点所在纬度
BaseData.Common.Site.Longitude =  double(fread(fid,1,'*float32'));   % Longitude of Radar Site 经度
BaseData.Common.Site.Height =  double(fread(fid,1,'*int32'));   % Height of  antenna in meters  天线高度（m）
BaseData.Common.Site.Ground =  fread(fid,1,'*int32');   % Height  of  ground  in meters  海拔高度
BaseData.Common.Site.Frequency =  fread(fid,1,'*float32');   % Radar operation frequency in MHz 雷达操作频率（MHz）
BaseData.Common.Site.BeamWidthHori  =  fread(fid,1,'*float32');   % Antenna  Beam  Width Hori 天线波束水平宽度
BaseData.Common.Site.BeamWidthVert =  fread(fid,1,'*float32');   % Antenna  Beam  Width Vert  天线波束垂直宽度
BaseData.Common.Site.Reserved =  fread(fid,60,'*uchar');    %Reserved 保留
%跳过第176个字节，开始
fseek(fid,176,'cof');
BaseData.Common.Task.CutNumber =  fread(fid,1,'*int32');    %  Number of Elevation or Azimuth cuts in the task
fseek(fid,76,'cof');

%% CUT CONFIG
for ii=1:BaseData.Common.Task.CutNumber
    fseek(fid,44,'cof');
    BaseData.Common.Cut(ii).LogResolution =  fread(fid,1,'*int32');    %Range  bin  resolution  for surveillance data, reflectivity and ZDR, etc
    BaseData.Common.Cut(ii).DopplerResolution =  fread(fid,1,'*int32');    %Range bin resolution for  Doppler data, velocity  and spectrum, etc
    BaseData.Common.Cut(ii).MaximumRange =  fread(fid,1,'*int32');    %Maximum range of scan
    fseek(fid,200,'cof');
end

%2 Basedata Radial Data
ii=0;
while(1)
    ii=ii+1;
    %2.1Basedata Radial Header Block
    BaseData.Radial(ii).Header.RadialState= fread(fid,1,'*int32');    %0= Cut Start 1=Intermediate Data 2=Cut End 3=Volume Start 4=Volume End
    RadialState(ii) = BaseData.Radial(ii).Header.RadialState;
    fseek(fid,8,'cof');
    BaseData.Radial(ii).Header.RadialNumber= fread(fid,1,'*int32');    %Radial Number for each cut
    BaseData.Radial(ii).Header.ElevationNumber= fread(fid,1,'*int32');    %Elevation Number
    BaseData.Radial(ii).Header.Azimuth= fread(fid,1,'*float32');    %Azimuth Angle
    BaseData.Radial(ii).Header.Elevation= fread(fid,1,'*float32');    %Elevation Angle
    fseek(fid,8,'cof');
    BaseData.Radial(ii).Header.Lengthofdata= fread(fid,1,'*int32');    %Length of data  in  this radial, this header is excluded
    BaseData.Radial(ii).Header.MomentNumber= fread(fid,1,'*int32');    %Moments available in this radial
    fseek(fid,20,'cof');  
    %2.2 Base Data Moment Header Block
    for jj = 1:BaseData.Radial(ii).Header.MomentNumber
        BaseData.Radial(ii).Moment(jj).Header.DataType = fread(fid,1,'*int32');    %Moment data type, See Table 2-7
        BaseData.Radial(ii).Moment(jj).Header.Scale = fread(fid,1,'*int32');    %Data coding scale  Code = value*scale+offset
        BaseData.Radial(ii).Moment(jj).Header.Offset = fread(fid,1,'*int32');    %Data coding offset Code = value*scale+offset
        BaseData.Radial(ii).Moment(jj).Header.BinLength  = fread(fid,1,'*int16');    %Bytes to save each bin of data
        BaseData.Radial(ii).Moment(jj).Header.Flags  = fread(fid,1,'*int16');    %Bit Mask of flags for data. Reserved now
        BaseData.Radial(ii).Moment(jj).Header.Length = fread(fid,1,'*int32');    %Length of data  of  current moment, this header is excluded.
        BaseData.Radial(ii).Moment(jj).Header.Reserved = fread(fid,12,'*uchar');    %
        %2.3 Base Data Moment data
       BaseData.Radial(ii).Moment(jj).Data= fread(fid,double(BaseData.Radial(ii).Moment(jj).Header.Length),'*uchar');
    end

    if ( (BaseData.Radial(ii).Header.RadialState==4) )   %此时说明体扫结束了！
        break;
    end
end
fclose(fid);

cut_end_index=find(RadialState==2);
cut_end_index(1,end+1)=ii;
size_index=size(cut_end_index,2)+1;
cut_end_index_final(2:size_index)=cut_end_index;
Cut_Radial_Number=diff(cut_end_index_final);

for ii=1:BaseData.Common.Task.CutNumber
    Data.Cut(ii).RadialNumber = Cut_Radial_Number(ii); 
    Scale =  double(BaseData.Radial(cut_end_index(ii)).Moment(Moment_Number).Header.Scale);
    Offset = double( BaseData.Radial(cut_end_index(ii)).Moment(Moment_Number).Header.Offset);
    BinLength = BaseData.Radial(cut_end_index(ii)).Moment(Moment_Number).Header.BinLength;

    for jj=1:Cut_Radial_Number(ii)
        Data.Cut(ii).Azimuth(jj) = BaseData.Radial(jj+cut_end_index_final(ii)).Header.Azimuth;
        Data.Cut(ii).Elevation(jj) = BaseData.Radial(jj+cut_end_index_final(ii)).Header.Elevation;

        if BinLength==2
            date_temp=single(BaseData.Radial(jj+cut_end_index_final(ii)).Moment(Moment_Number).Data(2:2:end)) *256 + single(BaseData.Radial(jj+cut_end_index_final(ii)).Moment(Moment_Number).Data(1:2:end));
        else
            date_temp=single(BaseData.Radial(jj+cut_end_index_final(ii)).Moment(Moment_Number).Data);
        end
        date_temp(date_temp==0) = NaN; 
        Data.Cut(ii).Moment(Moment_Number).Data(:,jj) = double((date_temp-Offset)/Scale);
    end         
end

Data.info.longitude = BaseData.Common.Site.Longitude;
Data.info.latitude = BaseData.Common.Site.Latitude;
Data.info.height = BaseData.Common.Site.Height;

radar = convert2radar(Data, Moment_Number);
end

function radar = convert2radar(data, Moment_Number)
%% 转换数据格式
cutnum = length(data.Cut);
for i = 1:cutnum
    r = 1:size(data.Cut(i).Moment(Moment_Number).Data, 1); 
    azimu = data.Cut(i).Azimuth;
    eleva = data.Cut(i).Elevation;
    
    [rr, azimuth] = ndgrid(r, azimu);
    [~, elevation] = ndgrid(r, eleva);
    
    prod = data.Cut(i).Moment(Moment_Number).Data;
    
    radar.products.elevation(i).data = prod;
    radar.products.elevation(i).elevation = data.Cut(i).Elevation(1);
    
    %[lat, lon, z] = sph2cart(deg2rad(azimuth), deg2rad(elevation), rr*75/1000);
    [lon, lat, z] = antenna_to_cartesian(rr*75, azimuth, elevation, data.info.height); 
    
    lat = double(km2deg(lat/1000)) + data.info.latitude;
    lon = double(km2deg(lon/1000)) + data.info.longitude;
    height = double(z) + data.info.height;    
    
    radar.coordinate.elevation(i).longitude.data = lon;
    radar.coordinate.elevation(i).longitude.units = 'degree';    
    radar.coordinate.elevation(i).latitude.data = lat;
    radar.coordinate.elevation(i).latitude.units = 'degree';
    radar.coordinate.elevation(i).height.data = height;
    radar.coordinate.elevation(i).height.units = 'm';  
    radar.coordinate.elevation(i).azimuth.data = azimuth;
    radar.coordinate.elevation(i).azimuth.units = 'degree';
    radar.coordinate.elevation(i).azimuth.description = 'azimuth for per elevation radar sweep';    
    radar.coordinate.elevation(i).elevation.data = elevation;
    radar.coordinate.elevation(i).elevation.units = 'degree';
    radar.coordinate.elevation(i).elevation.description = 'elevation for radar sweep';   
    
    radar.info.longitude.data = data.info.longitude;
    radar.info.longitude.units = 'degree';
    radar.info.latitude.data = data.info.latitude;
    radar.info.latitude.units = 'degree';
    radar.info.height.data = data.info.height;   
    radar.info.height.units = 'm';
    radar.info.elenum = cutnum;
end
end
