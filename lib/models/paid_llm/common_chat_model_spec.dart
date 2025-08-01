// ignore_for_file: constant_identifier_names

///
/// 定义云平台
/// 2024-07-08 这里的AI助手，估计只需要这个付费的就好了
///
enum ApiPlatform { lingyiwanwu }

// 模型对应的中文名
final Map<ApiPlatform, String> cpNames = {ApiPlatform.lingyiwanwu: '零一万物'};

// 云平台大模型post的地址
List<CusUrlSpec> platformUrls = [
  CusUrlSpec(
    ApiPlatform.lingyiwanwu,
    "chat",
    "https://api.lingyiwanwu.com/v1/chat/completions",
  ),
];

class CusUrlSpec {
  ApiPlatform platform; // 平台
  String type; // 类型(对话，文生图，图生文等，类型不同可能地址不一样)
  String url; // url地址

  CusUrlSpec(this.platform, this.type, this.url);
}

///
/// 文本对话
///

// 对话模型列表(chat completion model)
enum CCM { YiVision2, YiLightning }

/// 对话模型规格
class CCMSpec {
  ApiPlatform platform;
  String model;
  String name;
  bool isFree;
  bool? isVision;

  CCMSpec(
    this.platform,
    this.model,
    this.name, {
    this.isFree = false,
    this.isVision = false,
  });
}

/// 具体的模型信息
final Map<CCM, CCMSpec> ccmSpecList = {
  CCM.YiVision2: CCMSpec(ApiPlatform.lingyiwanwu, "yi-vision-v2", 'YiVision2'),
  CCM.YiLightning: CCMSpec(
    ApiPlatform.lingyiwanwu,
    "yi-lightning",
    'YiLightning',
  ),
};
