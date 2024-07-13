// ignore_for_file: constant_identifier_names

///
/// 定义云平台
/// 2024-07-08 这里的AI助手，估计只需要这个付费的就好了
///
enum ApiPlatform {
  lingyiwanwu,
}

// 模型对应的中文名
final Map<ApiPlatform, String> cpNames = {
  ApiPlatform.lingyiwanwu: '零一万物',
};

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
  String type; // 类型(对话，文生图，图生文等)
  String url; // url地址

  CusUrlSpec(this.platform, this.type, this.url);
}

///
/// 文本对话
///

// 对话模型列表(chat completion model)
enum CCM {
  // Yi前缀，零一万物中，全都收费的
  YiLarge,
  YiMedium,
  YiVision,
  YiMedium200k,
  YiSpark,
  YiLargeRag,
  YiLargeTurbo,
}

/// 对话模型规格
class CCMSpec {
  // 模型字符串(平台API参数的那个model的值)、模型名称、上下文长度数值，
  /// 是否免费，收费输入时百万token价格价格，输出时百万token价格(免费没写价格就先写0)
  ApiPlatform platform;
  String model;
  String name;
  int contextLength;
  bool isFree;
  // 每百万token单价
  double inputPrice;
  double outputPrice;
  // 是否是视觉理解大模型(即是否可以解析图片、分析图片内容，然后进行对话,使用时需要支持上传图片)
  bool? isVision;
  // 是否支持索引用实时全网检索信息服务
  bool? isQuote;
  // 模型特性
  String? feature;
  // 使用场景
  String? useCase;

  CCMSpec(this.platform, this.model, this.name, this.contextLength, this.isFree,
      this.inputPrice, this.outputPrice,
      {this.isVision = false,
      this.isQuote = false,
      this.feature,
      this.useCase});
}

/// 具体的模型信息
final Map<CCM, CCMSpec> ccmSpecList = {
  CCM.YiLarge: CCMSpec(
      ApiPlatform.lingyiwanwu, "yi-large", 'YiLarge', 32000, false, 20, 20,
      feature: """最新版本的yi-large模型。
          千亿参数大尺寸模型，提供超强问答及文本生成能力，具备极强的推理能力。
          并且对 System Prompt 做了专属强化。""",
      useCase: """适合于复杂语言理解、深度内容创作设计等复杂场景。"""),
  CCM.YiMedium: CCMSpec(
      ApiPlatform.lingyiwanwu, "yi-medium", 'YiMedium', 16000, false, 2.5, 2.5,
      feature: """中型尺寸模型升级微调，能力均衡，性价比高。深度优化指令遵循能力。""",
      useCase: """适用于日常聊天、问答、写作、翻译等通用场景，是企业级应用和AI大规模部署的理想选择。"""),
  CCM.YiVision: CCMSpec(
      ApiPlatform.lingyiwanwu, "yi-vision", 'YiVision', 4000, false, 6, 6,
      isVision: true,
      feature: """复杂视觉任务模型，提供高性能图片理解、分析能力。""",
      useCase: """适合需要分析和解释图像、图表的场景，如图片问答、图表理解、OCR、视觉推理、教育、研究报告理解或多语种文档阅读等。"""),
  CCM.YiMedium200k: CCMSpec(ApiPlatform.lingyiwanwu, "yi-medium-200k",
      'YiMedium200k', 200000, false, 12, 12,
      feature: """200K超长上下文窗口，提供长文本深度理解和生成能力。""",
      useCase: """适用于长文本的理解和生成，如文档阅读、问答、构建知识库等场景。"""),
  CCM.YiSpark: CCMSpec(
      ApiPlatform.lingyiwanwu, "yi-spark", 'YiSpark', 16000, false, 1, 1,
      feature: """小而精悍，轻量极速模型。提供强化数学运算和代码编写能力。""",
      useCase: """适用于轻量化数学分析、代码生成、文本聊天等场景。"""),
  CCM.YiLargeRag: CCMSpec(ApiPlatform.lingyiwanwu, "yi-large-rag", 'YiLargeRag',
      16000, false, 25, 25,
      isQuote: true,
      feature: """实时全网检索信息服务，模型进阶能力。基于yi-large模型，结合检索与生成技术提供精准答案。""",
      useCase: """适用于需要结合实时信息，进行复杂推理、文本生成等场景。"""),
  CCM.YiLargeTurbo: CCMSpec(ApiPlatform.lingyiwanwu, "yi-large-turbo",
      'YiLargeTurbo', 16000, false, 12, 12,
      feature: """超高性价比、卓越性能。根据性能和推理速度、成本，进行平衡性高精度调优。""",
      useCase: """适用于全场景、高品质的推理及文本生成等场景。"""),
};
