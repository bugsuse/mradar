# mradar

## 处理雷达数据的matlab程序包

### 支持的雷达数据格式：

   * SA/SB 波段雷达基数据
   * 南信大 C 波段双偏振多普勒雷达

其它有待添加

### 支持的功能：

  * 根据 PPI 扫描数据，通过给定起始点和终点坐标或给定中点坐标和角度提取任意剖面数据
  * 根据 PPI 扫描数据，给定任意方位角，提取RHI扫描数据


## 使用方法

下载源码之后将源码放到 mradar 文件夹中，然后在 mradar 路径下执行 setup_mradar 函数即可将添加路径

`>> setup_mradar`

如果所有测试数据均在 data 子文件夹内，可在 mradar 路径下直接运行测试程序

`>> sband_demo`


## 效果


<center> 基本反射率 </center>
<div align=center>
      <img src="images/sband_base.jpg">
</div>

<center> 任意剖面图 </center>
<div align=center>
      <img src="images/sband_cross_section_ppi.jpg">
</div>

<center> 固定方位角RHI </center>
<div align=center>
      <img src="images/sband_rhi.jpg">
</div>
                                   
