// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get node => '节点';

  @override
  String get inbound => '入站';

  @override
  String get start => '启动';

  @override
  String get log => '日志';

  @override
  String get logLevel => '日志级别';

  @override
  String get settings => '设置';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get routing => '路由';

  @override
  String get whileList => '白名单';

  @override
  String get gfw => '黑名单';

  @override
  String get proxyAll => '全局';

  @override
  String get auto => '自动';

  @override
  String get systemProxy => '系统代理';

  @override
  String get inputManually => '手动输入';

  @override
  String get qrCode => '二维码';

  @override
  String get addNode => '添加节点';

  @override
  String get photo => '图片';

  @override
  String get clipboard => '剪贴板';

  @override
  String get protocol => '协议';

  @override
  String get add => '添加';

  @override
  String get addToHomeScreen => '添加到主页';

  @override
  String get name => '名称';

  @override
  String get domainStrategy => '域名策略';

  @override
  String get enableMux => '启用Mux';

  @override
  String get address => '地址';

  @override
  String get ipOrDomain => 'IP / 域名';

  @override
  String get port => '端口';

  @override
  String get nodeSelection => '节点选择';

  @override
  String get server => '服务器';

  @override
  String get compass => '指南';

  @override
  String get home => '主页';

  @override
  String get connecting => '连接中';

  @override
  String get connected => '已连接';

  @override
  String get disconnecting => '正在断开连接';

  @override
  String get disconnected => '未连接';

  @override
  String get subscription => '订阅';

  @override
  String get autoUpdate => '自动更新';

  @override
  String get unknown => '未知';

  @override
  String get preparing => '准备中';

  @override
  String get edit => '编辑';

  @override
  String get speedTest => '速度测试';

  @override
  String get statusTest => '可用测试';

  @override
  String get selfhost => '自建';

  @override
  String get free => '免费';

  @override
  String get reconnecting => '重连中';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get password => '密码';

  @override
  String get accountName => '用户名';

  @override
  String get delete => '删除';

  @override
  String get hide => '从主页隐藏';

  @override
  String get gettingNodesSubscriptions => '获取节点/订阅中';

  @override
  String get emptyClipboard => '剪切板为空';

  @override
  String get decodeQrCode => '无法解码二维码';

  @override
  String get proxy => '代理';

  @override
  String get direct => '直连';

  @override
  String get promote => '推广';

  @override
  String get domainsOrIps => '域名/IP';

  @override
  String get addProxyDomainIp => '添加代理域名/IP';

  @override
  String get addDirectDomainIp => '添加直连域名/IP';

  @override
  String get domain => '域名';

  @override
  String get type => '类型';

  @override
  String get invalidIp => '无效的IP';

  @override
  String get invalidCidr => '无效的CIDR';

  @override
  String get exact => '精确';

  @override
  String get regularExpression => '正则';

  @override
  String get keyword => '关键字';

  @override
  String get rootDomain => '根域名';

  @override
  String get addServer => '添加服务器';

  @override
  String get editServer => '编辑服务器';

  @override
  String get sshKey => 'SSH密钥';

  @override
  String get selectFromFile => '从文件中选择';

  @override
  String get sudoPassword => 'sudo密码';

  @override
  String get statusMonitor => '状态监控';

  @override
  String get fieldRequired => '此项不能为空';

  @override
  String get invalidPort => '端口有误';

  @override
  String get invalidAddress => '地址有误';

  @override
  String get failedToAddServer => '添加服务器失败';

  @override
  String get memory => '内存';

  @override
  String get storage => '空间';

  @override
  String get serverPubKey => '服务器公钥';

  @override
  String get serverPubKeyHelper => '如果省略,服务器在第一次连接时发来的任何公钥都会被接受,此后的连接都会使用这个公钥';

  @override
  String get failedConnectServer => '连接失败';

  @override
  String get retry => '重试';

  @override
  String get keyPassphrase => '密钥密码';

  @override
  String get showRealtimeStatus => '显示实时状态';

  @override
  String get hideRealtimeStatus => '隐藏实时状态';

  @override
  String get app => '应用';

  @override
  String get appName => '应用名称';

  @override
  String get prefix => '前缀';

  @override
  String get confirm => '确定';

  @override
  String get addToProxy => '添加到代理?';

  @override
  String get addToDirect => '添加到直连?';

  @override
  String get default0 => '默认';

  @override
  String get website => '网站';

  @override
  String get endTime => '到期日';

  @override
  String get remainingData => '剩余流量';

  @override
  String get update => '更新';

  @override
  String get actions => '动作';

  @override
  String get updateInterval => '更新间隔';

  @override
  String get testArea => '地区检测';

  @override
  String get autoDownload => '自动下载新版本';

  @override
  String get unableToGetNodes => '获取节点失败，请复制正确格式的订阅链接后重试';

  @override
  String get unableToGetNodesEmptyClipboard => '获取节点失败，剪贴板无内容';

  @override
  String get subscriptionAddress => '订阅地址';

  @override
  String get subscriptionShareLinkQueryExtra => '附加参数';

  @override
  String get subscriptionShareLinkQueryExtraHint => 'tx=10&foo=1&sig=a1b2';

  @override
  String get subscriptionShareLinkQueryExtraHelper => '在解析前追加到每个节点的订阅链接。';

  @override
  String get subscriptionShareLinkQueryExtraInvalid => '请填写有效的 JSON 对象或查询字符串（例如 key=value&key2=value2）';

  @override
  String get empty => '空';

  @override
  String get invalidHttp => '无效的HTTPS地址';

  @override
  String get noNode => '无节点';

  @override
  String get failedToChangeOutboundMode => '无法设置出站选择';

  @override
  String get failedToChangeFakeDns => '设置Fake DNS失败';

  @override
  String get failedToChangeRoutingMode => '设置路由模式失败';

  @override
  String get disableInAuto => '自动模式下禁用';

  @override
  String get area => '地区';

  @override
  String get remark => '备注';

  @override
  String get remarkAddress => '备注·地址';

  @override
  String get usable => '可用';

  @override
  String get speed => '速度';

  @override
  String get latency => '延迟';

  @override
  String get recent => '最近';

  @override
  String get selectOneOutbound => '使用';

  @override
  String get addFailedUniqueConstraint => '添加规则失败,与已有的规则冲突';

  @override
  String get enableInAuto => '自动模式下启用';

  @override
  String get homeCustomizeDragHint => '拖动卡片可以重新排序，隐藏的卡片会移动到底部托盘。';

  @override
  String get homeCustomizeResetOrder => '重置顺序';

  @override
  String get homeCustomizeHiddenTitle => '已隐藏';

  @override
  String get homeCustomizeDropHere => '拖放到这里以添加到列底部';

  @override
  String get homeCustomizeMergeWith => '合并到…';

  @override
  String get homeCustomizeNoMergeTargets => '没有可合并的小部件';

  @override
  String get compact => '紧凑';

  @override
  String get medium => '中等';

  @override
  String get large => '大';

  @override
  String get showClient => '显示客户端';

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开';

  @override
  String disconnectedUnexpectedly(String reason) {
    return '连接意外断开。原因: $reason';
  }

  @override
  String get quit => '退出';

  @override
  String get iosAppRoutingNoSupport => 'iOS目前不支持应用路由';

  @override
  String get failedToChangeInboundMode => '入站模式切换失败';

  @override
  String get language => '语言';

  @override
  String get mannual => '手动';

  @override
  String get updatedAt => '更新于';

  @override
  String min(num value) {
    final intl.NumberFormat valueNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString分钟';
  }

  @override
  String hour(num value) {
    final intl.NumberFormat valueNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString小时';
  }

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get contactUs => '联系我们';

  @override
  String get openSourceSoftwareNotice => '开源软件声明';

  @override
  String get copy => '复制';

  @override
  String get privacyPolicySummary => 'VX只在下方按钮开启的情况下收集诊断日志，这些日志不包含您的个人数据。详细的隐私政策请点击下方按钮查看。';

  @override
  String get diagnosticLogDoesNotContainPersonalData => '诊断日志不与您建立关联，也不包含个人数据';

  @override
  String get shareDiagnosticLogWithDeveloper => '分享诊断日志给开发者';

  @override
  String get shareCnDirectAppsWithDeveloper => '帮助完善中国应用路由（分享直连应用列表）';

  @override
  String get shareCnDirectAppsDescription => '开启后，在您编辑完成直连应用集合时，将匿名上传您「直连」应用集合中的应用包名与显示名称，用于汇总中国常用应用列表(该列表会发布在VX文档网站上)。上传的应用列表不与您建立关联。';

  @override
  String get yes => '好的';

  @override
  String get no => '不';

  @override
  String get contactUsSummary => '您可以通过以下方式联系我们。';

  @override
  String get contactUsFreely => '如果您在使用VX的过程中有任何问题或需要任何功能，请随时联系我们。';

  @override
  String get contactUsProPriority => '如果您是 Pro 用户，联系我们时请告知，我们会优先处理 Pro 用户的咨询。Pro用户可以加入电报群组，如需加入，请通过邮件联系我们，我们会向您发送邀请链接。';

  @override
  String get bugAreWelcome => '欢迎向我们反馈bug和建议，谢谢!';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get sourceCodeUrl => '源码链接';

  @override
  String get email => '邮箱';

  @override
  String get verificationCode => '验证码';

  @override
  String get send => '发送';

  @override
  String get login => '登录';

  @override
  String get loginWithEmail => '邮箱登录';

  @override
  String get loginWithGoogle => '谷歌';

  @override
  String get loginWithApple => '苹果';

  @override
  String get loginWithMicrosoft => '微软';

  @override
  String get newUserTrialText => '新用户可免费试用Pro 7天';

  @override
  String get proExpiredAt => 'Pro 到期时间';

  @override
  String get addGroup => '添加分组';

  @override
  String get deleteGroup => '删除分组';

  @override
  String get deleteGroupAndNodes => '删除分组和节点';

  @override
  String get group => '分组';

  @override
  String get addToGroup => '添加至分组';

  @override
  String get addToAppSet => '添加至应用集合';

  @override
  String get addToDomainSet => '添加至域名集合';

  @override
  String get addToIpSet => '添加至IP集合';

  @override
  String logDnsResolver(String resolver) {
    return 'DNS: $resolver';
  }

  @override
  String get addApp => '添加应用';

  @override
  String get noSelectedNode => '无选中节点';

  @override
  String get pleaseSelectNode => '请选择一个节点';

  @override
  String get pleaseSelectSelector => '请选择一个选择器';

  @override
  String get pleaseEnterRuleName => '请输入规则名称';

  @override
  String get ruleName => '命中规则名称';

  @override
  String get matchAll => '匹配所有';

  @override
  String get ruleMatchCondition => '当任一条件成立时，规则匹配。如果条件数量为零，规则不会匹配。';

  @override
  String get conditionMatch => '当所有子条件成立时，该条件成立。如果子条件数量为零，该条件不成立。';

  @override
  String get inboundLabel => '入站';

  @override
  String get domainSet => '域名集合';

  @override
  String get appSet => '应用集合';

  @override
  String get ipSet => 'IP集合';

  @override
  String get addRouterRule => '添加路由规则';

  @override
  String get addDnsRule => '添加DNS规则';

  @override
  String get editRule => '编辑规则';

  @override
  String get addRouter => '添加路由模式';

  @override
  String get copyDefault => '复制默认';

  @override
  String get ruleOrder => '规则由上到下依次进行匹配';

  @override
  String get nodeChain => '代理链';

  @override
  String get nodeChainDesc => '被该选择器选中的节点将与以下节点成一个代理链。[你的流量] -> [选择器选中的节点] -> [下面的第一个节点] -> ... -> [下面的最后一个节点] -> [最终目的地]';

  @override
  String get addSelector => '添加选择器';

  @override
  String get selectorNameDuplicate => '选择器名称不能重复';

  @override
  String get renameSelector => '重命名选择器';

  @override
  String get allNodes => '全部节点';

  @override
  String get partialNodes => '部分节点';

  @override
  String get nodeGroup => '节点组';

  @override
  String get lowestLatency => '最低延迟';

  @override
  String get lowLatency => '低延迟';

  @override
  String get highThroughput => '高速度';

  @override
  String get nameCannotBeEmpty => '名称不能为空';

  @override
  String get setNameDuplicate => '集合的名称不能重复';

  @override
  String get mutuallyExclusiveSetName => '互斥集合名称';

  @override
  String get include => '包含';

  @override
  String get exclude => '排除';

  @override
  String get simple => '简易';

  @override
  String get advanced => '高级';

  @override
  String get customDirect => '自定义直连';

  @override
  String get customProxy => '自定义代理';

  @override
  String get cnGames => 'CN游戏';

  @override
  String get private => '私有';

  @override
  String get gfwWithoutCustomDirect => 'GFW(不包含自定义直连)';

  @override
  String get gfwModeProxyDomains => 'GFW模式代理域名';

  @override
  String get gfwModeProxyIps => 'GFW模式代理IP';

  @override
  String get cnModeProxyDomains => 'CN模式代理域名';

  @override
  String get cnModeDirectDomains => 'CN模式直连域名';

  @override
  String get cnModeDirectIps => 'CN模式直连IP';

  @override
  String get proxyAllModeProxyDomains => '全局模式代理域名';

  @override
  String get proxyAllModeDirectDomains => '全局模式直连域名';

  @override
  String get proxyAllModeDirectIps => '全局模式直连IP';

  @override
  String get ruBlockModeProxyDomains => '俄罗斯屏蔽(全部)模式代理域名';

  @override
  String get ruBlockModeProxyIps => '俄罗斯屏蔽(全部)模式代理IP';

  @override
  String get ruBlockAllModeProxyDomains => '俄罗斯屏蔽(全部)模式代理域名';

  @override
  String get ruBlockAllModeProxyIps => '俄罗斯屏蔽(全部)模式代理IP';

  @override
  String get ipToDomain => 'IP -> 域名';

  @override
  String get showSessionOngoingIndicator => '显示会话进行中指示器';

  @override
  String get hideSessionOngoingIndicator => '隐藏会话进行中指示器';

  @override
  String get showRealtimeUsage => '显示实时使用情况';

  @override
  String get hideRealtimeUsage => '隐藏实时使用情况';

  @override
  String get dismissSameDestination => '隐藏相同目标';

  @override
  String get showSameDestination => '显示相同目标';

  @override
  String get proFeatureDescription => '该功能为Pro功能，升级为Pro用户即可解锁全部功能';

  @override
  String get becomePermanentPro => '永久成为Pro用户';

  @override
  String get becomePermanentProDescription => '永久成为Pro用户';

  @override
  String get tryPro => '试用Pro';

  @override
  String get newUserProTrial => '新用户可试用Pro7天';

  @override
  String get purchase => '购买';

  @override
  String get purchaseCancelled => '购买已取消';

  @override
  String get verifyingPurchase => '正在验证购买...';

  @override
  String get restoringPurchase => '正在恢复购买...';

  @override
  String purchaseVerificationFailed(String reason) {
    return '无法验证购买: $reason';
  }

  @override
  String ifYouHavePaid(String orderId) {
    return '如果您已支付，请不要担心，您的支付会被商店自动退款。如果有任何问题，请联系我们。订单ID: $orderId';
  }

  @override
  String get invalidPurchase => '无效购买';

  @override
  String get purchaseSuccessful => '购买成功';

  @override
  String purchaseFailed(String status) {
    return '购买失败: $status';
  }

  @override
  String get unableToConnectToStore => '无法与商店连接';

  @override
  String get loginBeforePurchase => '购买前请先登录';

  @override
  String get loginBeforeRestore => '恢复购买购买前请先登录';

  @override
  String get visitWebsiteToPurchasePro => '请访问我们的网站购买 Pro';

  @override
  String get upgradeToPermanentPro => '升级为永久Pro';

  @override
  String get upgradeToMax => '升级为永久Max';

  @override
  String get caseInsensitive => '不区分大小写';

  @override
  String get startFailed => '启动失败';

  @override
  String startFailedWithReason(String reason, String stackTrace) {
    return '启动失败: $reason. StackTrace: $stackTrace';
  }

  @override
  String get startFailedReasonTunNeedAdmin => 'TUN入站模式需要以管理员身份运行VX或者安装Service（在设置页面安装）';

  @override
  String get startFailedReasonNoNode => '无节点';

  @override
  String get startFailedReasonNoEnabledNode => '无启用节点，请至少启用一个节点';

  @override
  String get startFailedReasonNoSelected => '未选择节点';

  @override
  String failedToUpdateSub(String value) {
    return '更新订阅“$value”失败';
  }

  @override
  String get failedToAddSubscription => '添加订阅失败，此订阅已存在';

  @override
  String get tunNeedAdmin => 'TUN需要以管理员身份运行';

  @override
  String get windowsServiceRequiresAdmin => '此操作需要管理员权限。请以管理员身份重启 VX 后重试。';

  @override
  String windowsServiceInstallFailed(String error) {
    return 'VX Service 安装失败：$error';
  }

  @override
  String get windowsServiceInstalled => 'VX Service 已安装';

  @override
  String get windowsServiceRemoved => 'VX Service 已移除';

  @override
  String get windowsServiceInstall => '安装 VX Service';

  @override
  String get windowsServiceRemove => '移除 VX Service';

  @override
  String decodeResult(num value1, num value2) {
    final intl.NumberFormat value1NumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String value1String = value1NumberFormat.format(value1);
    final intl.NumberFormat value2NumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String value2String = value2NumberFormat.format(value2);

    return '成功获取$value1String个节点，失败$value2String个节点';
  }

  @override
  String updateSubResult(num value1, num value2, num value3, num value4) {
    final intl.NumberFormat value1NumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String value1String = value1NumberFormat.format(value1);
    final intl.NumberFormat value2NumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String value2String = value2NumberFormat.format(value2);
    final intl.NumberFormat value3NumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String value3String = value3NumberFormat.format(value3);
    final intl.NumberFormat value4NumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String value4String = value4NumberFormat.format(value4);

    return '成功更新$value1String个订阅，失败$value2String个订阅; 成功添加$value3String个节点，失败$value4String个节点';
  }

  @override
  String get failedToUpdateCountry => '更新地区失败';

  @override
  String get keepAlivePeriodMustBeBetween2And60 => '必须在2到60之间';

  @override
  String get showApp => '显示应用';

  @override
  String get hideApp => '隐藏应用';

  @override
  String get showSystemApps => '显示系统应用';

  @override
  String get hideSystemApps => '隐藏系统应用';

  @override
  String get doubleTapToDelete => '双击删除';

  @override
  String get method => '方法';

  @override
  String get sshKeyPath => '密钥文件路径';

  @override
  String get useCommonSshKey => '使用已有SSH密钥';

  @override
  String get addCommonSshKey => '添加SSH密钥';

  @override
  String get sshKeyContentOrPathRequired => '密钥内容或密钥文件路径不能同时为空';

  @override
  String get failedToAddCommonSshKey => '添加SSH密钥失败';

  @override
  String get failedToAddCommonSshKeyDueToDuplicateName => '添加SSH密钥失败，因为存在同名密钥';

  @override
  String get quickDeploy => '快捷部署';

  @override
  String get deploy => '部署';

  @override
  String get close => '关闭';

  @override
  String deploySuccess(String deploy, String server) {
    return '服务器$server $deploy 部署成功';
  }

  @override
  String bbrError(String error) {
    return '启用BBR失败: $error';
  }

  @override
  String firewallError(String error) {
    return '禁用OS防火墙失败: $error';
  }

  @override
  String failedToDeploy(String value) {
    return '部署失败: $value';
  }

  @override
  String get peerCertChainSHA256Hash => 'SHA256';

  @override
  String get serverCA => 'Root CA';

  @override
  String failedToInitGrpcClient(String value) {
    return '无法初始化grpc客户端: $value';
  }

  @override
  String get block => '屏蔽';

  @override
  String get failure => '失败';

  @override
  String get appKeyword => '应用关键字';

  @override
  String get sniffDomain => '嗅探域名';

  @override
  String get trafficStats => '流量统计';

  @override
  String get useSshKey => '使用SSH密钥';

  @override
  String get errorOnly => '只显示错误';

  @override
  String get all => '全部';

  @override
  String get failedToUndoBlockDns => '移除WFP设置失败，请关闭此应用，WFP设置将在应用关闭后自动移除';

  @override
  String get failedToRemoveSystemProxy => '移除系统代理失败，请手动在设置中移除';

  @override
  String failedToChangeNode(String value) {
    return '切换节点失败: $value';
  }

  @override
  String get failureDetail => '失败详情';

  @override
  String get failedNodes => '失败节点';

  @override
  String get failedSub => '失败订阅';

  @override
  String get addRemark => '添加一个备注?';

  @override
  String get multiSelect => '多选';

  @override
  String get share => '分享';

  @override
  String get quickAction => '一键操作';

  @override
  String get deleteUnusable => '删除不可用节点';

  @override
  String get smallScreenPreference => '小尺寸屏幕偏好';

  @override
  String get chainProxy => '链式代理';

  @override
  String get singleNode => '单节点';

  @override
  String get multipleNodes => '多节点';

  @override
  String get balanceStrategy => '负载均衡';

  @override
  String get manualNodeMode => '手动模式';

  @override
  String get outboundMode => '出站';

  @override
  String get random => '随机';

  @override
  String get mode => '模式';

  @override
  String get balanceStrategyMemory => '记忆';

  @override
  String get selectingStrategy => '选择策略';

  @override
  String get mostThroughput => '最高速度';

  @override
  String get allOk => '可用';

  @override
  String get yourDevices => '你的设备';

  @override
  String get destination => '目的地';

  @override
  String get addNewNode => '添加新节点';

  @override
  String get useExistingNode => '使用已有节点';

  @override
  String get atLeastTwoNodes => '至少需要两个节点';

  @override
  String get advancedMode => '高级模式';

  @override
  String get simpleMode => '简单模式';

  @override
  String get rule => '规则';

  @override
  String get set => '集合';

  @override
  String get selector => '选择器';

  @override
  String get atmoicDomainSet => '域名小集合';

  @override
  String get greatDomainSet => '域名大集合';

  @override
  String get atmoicIpSet => 'IP小集合';

  @override
  String get greatIpSet => 'IP大集合';

  @override
  String get createGreatDomainSet => '创建域名大集合';

  @override
  String get editGreatDomainSet => '编辑域名大集合';

  @override
  String get createSmallDomainSet => '创建域名小集合';

  @override
  String get editSmallDomainSet => '编辑域名小集合';

  @override
  String get editGreatIpSet => '编辑IP大集合';

  @override
  String get createGreatIpSet => '创建IP大集合';

  @override
  String get editAppSet => '编辑应用集合';

  @override
  String get condition => '条件';

  @override
  String get range => '范围';

  @override
  String get account => '账户';

  @override
  String get logout => '登出';

  @override
  String get geoSiteOrGeoIPFileNotFound => '正在下载Geo文件...';

  @override
  String get createIpSmallSet => '创建IP小集合';

  @override
  String get editIpSmallSet => '编辑IP小集合';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get deleteAccountConfirm => '确定要删除账户吗？此操作无法撤销。';

  @override
  String get domainSetDescription => '以下域名集合使用代理DNS服务器（默认为8.8.8.8和1.1.1.1）解析，其余域名使用直连DNS服务器（默认是物理网卡的DNS服务器，或223.5.5.5和114.114.114.114如果物理网卡的DNS服务器无法获取到）解析';

  @override
  String get routerRuleDescription => '对于每一个连接，规则由上到下依次进行匹配，一旦匹配成功，后面的规则不会在被考虑。如果没有匹配到规则，此连接将会失败';

  @override
  String get dstIpSet => '目标IP集合';

  @override
  String get ruleNameVXTestNodes => 'VX节点测试';

  @override
  String get ruleNameInternalDnsProxyGoProxy => '内部DNS CF';

  @override
  String get ruleNameInternalDnsDirectGoDirect => '内部DNS 阿里云&CF';

  @override
  String get ruleNameProxyDnsServerGoProxy => '默认代理DNS服务器';

  @override
  String get ruleNameDirectDnsServerGoDirect => '默认直连DNS服务器';

  @override
  String get ruleNameDnsHijack => 'DNS劫持:非直连域名';

  @override
  String get ruleNameCustomDirectDomain => '自定义直连域名';

  @override
  String get ruleNameCustomDirectIp => '自定义直连IP';

  @override
  String get ruleNameCustomProxyDomain => '自定义代理域名';

  @override
  String get ruleNameCustomProxyIp => '自定义代理IP';

  @override
  String get ruleNameProxyApp => '代理应用';

  @override
  String get ruleNameDirectApp => '直连应用';

  @override
  String get ruleNameCnDirectIp => 'CN模式直连IP';

  @override
  String get ruleNameDefaultProxy => '默认代理';

  @override
  String get ruleNameCnDirectDomain => 'CN模式直连域名';

  @override
  String get ruleNameGfwProxyDomain => 'GFW模式代理域名';

  @override
  String get ruleNameGfwProxyIp => 'GFW模式代理IP';

  @override
  String get ruleNameRuBlockProxyDomain => '俄罗斯屏蔽(全部)模式代理域名';

  @override
  String get ruleNameRuBlockProxyIp => '俄罗斯屏蔽(全部)模式代理IP';

  @override
  String get ruleNameRuBlockAllProxyDomain => '俄罗斯屏蔽(全部)模式代理域名';

  @override
  String get ruleNameRuBlockAllProxyIp => '俄罗斯屏蔽(全部)模式代理IP';

  @override
  String get ruleNameDefaultDirect => '默认直连';

  @override
  String get ruleNameGlobalDirectDomain => '全局模式直连域名';

  @override
  String get ruleNameGlobalDirectIp => '全局模式直连IP';

  @override
  String get addAppSet => '添加应用集合';

  @override
  String get pro => '永久Pro账户';

  @override
  String get proxyShare => '代理共享';

  @override
  String get sniff => '嗅探';

  @override
  String get proxyShareDesc => '启动VPN后开启HTTP和SOCKS入站，以使局域网内其他设备通过本机上网。（入站名称为“proxyShare”）';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get emailLogin => '邮箱登录';

  @override
  String get google => '谷歌';

  @override
  String get apple => '苹果';

  @override
  String get microsoft => '微软';

  @override
  String get rateApp => '评价VX';

  @override
  String get userConsend => '一旦登录成功，您的邮箱将存储在我们的服务器，直到您删除账户为止。这是为了提供账户登录功能所必需的个人信息。我们不会与任何第三方分享您的邮箱。您是否允许我们存储您的邮箱？';

  @override
  String get okay => '好的';

  @override
  String get disagree => '不同意';

  @override
  String get reject => '拒绝';

  @override
  String get greatSetDescription1 => '大集合由小集合或大集合组成。当判断一个域名/IP是否在集合中时，首先会考虑排除集合，如果域名在排除的集合中，则域名不在集合中。';

  @override
  String get greatSetDescription2 => '一个大集合可以有一个互斥集合。如果一个域名/IP在集合A内，则该域名/IP不在集合A的互斥集合内。';

  @override
  String get pleaseLoginFirst => '请先登录';

  @override
  String get telegram => '电报';

  @override
  String failedToDownloadGeoData(String value) {
    return '下载GeoData失败: $value';
  }

  @override
  String get doNotUse1080IOS => 'iOS上无法使用1080端口';

  @override
  String get deletedNode => '已删除的节点';

  @override
  String selectorContainsDeletedLandHandler(String value) {
    return '选择器$value使用已删除的节点作为落地节点，请删除该落地节点并重试';
  }

  @override
  String get tunIpv6Settings => 'TUN 设置';

  @override
  String get alwaysEnableIpv6 => '总是启用IPv6';

  @override
  String get dependsOnDefaultNic => '取决于默认物理网卡';

  @override
  String get dependsOnDefaultNicDesc => '如果默认物理网卡支持IPv6，TUN网卡也支持IPv6';

  @override
  String get tunIpv4Desc => '此设置下，在Windows/Linux上，如果物理网卡支持IPv6，IPv6流量将不会被VX TUN处理，而是会被物理网卡处理，也就是说它们会由物理网卡直接发出；在Android/iOS/macOS上，IPv6流量将被阻止。';

  @override
  String get tunRejectIpv6 => '拒绝 IPv6（如果节点不支持它）';

  @override
  String get tunRejectIpv6Desc => '如果根据目标、源、应用（如果有）匹配到的节点不支持IPv6，则拒绝该连接';

  @override
  String get tunCidr4 => 'TUN IPv4 地址 (CIDR)';

  @override
  String get tunCidr6 => 'TUN IPv6 地址 (CIDR)';

  @override
  String get tunCidr4Hint => '例如 172.23.27.1/24';

  @override
  String get tunCidr6Hint => '例如 fc20::1/120';

  @override
  String get tunDns4 => 'TUN DNS IPv4';

  @override
  String get tunDns6 => 'TUN DNS IPv6';

  @override
  String get tunDns4Hint => '例如 172.23.27.2（多个用逗号分隔）';

  @override
  String get tunDns6Hint => '例如 fc20::2（多个用逗号分隔）';

  @override
  String get tunRoutes4 => 'TUN IPv4 路由';

  @override
  String get tunRoutes6 => 'TUN IPv6 路由';

  @override
  String get tunRoutes4Hint => '例如 0.0.0.0/0（多个用逗号分隔）';

  @override
  String get tunRoutes6Hint => '例如 ::/0（多个用逗号分隔）';

  @override
  String get tunMtu => 'TUN MTU';

  @override
  String get tunMtuHint => '留空为系统默认';

  @override
  String failedToCreateAllFirstLaunch(String value) {
    return '初始化数据库失败: $value';
  }

  @override
  String failedToInsertDefaultData(String value) {
    return '数据库添加默认数据失败: $value';
  }

  @override
  String newVersionDownloadedDialog(String version) {
    return '新版本$version已下载，是否安装？';
  }

  @override
  String get skipThisVersion => '跳过此版本';

  @override
  String get install => '安装';

  @override
  String get later => '暂时不安装';

  @override
  String get skip => '跳过';

  @override
  String get autoCheck => '自动检查新版本';

  @override
  String downloading(String value) {
    return '正在下载$value...';
  }

  @override
  String installFailed(String reason) {
    return '安装失败: $reason';
  }

  @override
  String get tun46SettingIpv4Only => 'IPv4';

  @override
  String get tun46SettingIpv4AndIpv6 => 'IPv4 & IPv6';

  @override
  String get ad => '广告';

  @override
  String get advancedSettingDesc => 'VPN相关设置';

  @override
  String get general => '通用';

  @override
  String get customizeHomeWidgets => '自定义主页';

  @override
  String get customizeHomeWidgetsDesc => '选择在主页上显示哪些模块。';

  @override
  String get homeWidgetStats => '速度与统计';

  @override
  String get homeWidgetNodesHelper => '节点助手';

  @override
  String get homeWidgetNodes => '当前节点';

  @override
  String get light => '亮色';

  @override
  String get dark => '暗色';

  @override
  String get system => '系统';

  @override
  String get themeMode => '主题';

  @override
  String get serverError => '服务器错误';

  @override
  String get gfwDesc => '所有被GFW屏蔽的域名/IP使用代理，其他使用直连';

  @override
  String get cnDesc => '中国大陆的域名/IP使用直连，其他均使用代理';

  @override
  String get proxyAllDesc => '除私有地址外所有域名/IP均使用代理';

  @override
  String get dnsRule => 'DNS规则';

  @override
  String get dnsRuleNameGfwProxyFake => 'GFW模式代理域名 & 非中国大陆域名(A/AAAA)';

  @override
  String get dnsRuleNameGfwProxy => 'GFW模式代理域名';

  @override
  String get dnsRuleNameRuBlockProxyFake => '俄罗斯屏蔽(全部)模式代理域名A/AAAA';

  @override
  String get dnsRuleNameRuBlockProxy => '俄罗斯屏蔽(全部)模式代理域名';

  @override
  String get dnsRuleNameRuBlockAllProxyFake => '俄罗斯屏蔽(全部)模式代理域名A/AAAA';

  @override
  String get dnsRuleNameRuBlockAllProxy => '俄罗斯屏蔽(全部)模式代理域名';

  @override
  String get dnsRuleNameCnProxyFake => 'CN模式代理域名A/AAAA';

  @override
  String get dnsRuleNameCnProxy => 'CN模式代理域名';

  @override
  String get dnsRuleNameProxyAllProxyFake => '全局模式代理域名A/AAAA';

  @override
  String get dnsRuleNameProxyAllProxy => '全局模式代理域名';

  @override
  String get dnsRuleNameDefaultDirect => '其余';

  @override
  String get routerRules => '路由规则';

  @override
  String get dnsRuleDesc => '对于每一个DNS请求，DNS规则从上到下依次进行匹配，一旦匹配成功，该规则所指定的DNS服务器将被用来处理该DNS请求。如果没有规则匹配，返回空的DNS结果。';

  @override
  String get dnsServer => 'DNS服务器';

  @override
  String get howDnsRuleMatch => '当所有条件成立或该规则没有任何条件启用时，规则匹配。';

  @override
  String get selectAtleastOneDnsServer => '请选择一个DNS服务器';

  @override
  String get dnsType => 'DNS类型';

  @override
  String get directDnsServer => '直连DNS服务器';

  @override
  String get proxyDnsServer => '代理DNS服务器';

  @override
  String get addDnsServer => '添加DNS服务器';

  @override
  String get useDefaultDnsServer => '使用物理网卡的DNS服务器。如无法获取到物理网卡的DNS服务器，使用输入的服务器';

  @override
  String get useDefaultNicDnsServer => '使用物理网卡的DNS服务器。如无法获取到物理网卡的DNS服务器，使用以下服务器：';

  @override
  String get addDnsAddressHint => '该类型支持多地址。使用“,”分隔。每一个DNS请求会被同时发往所有地址，第一个返回的结果将被采用';

  @override
  String get invalidUrl => '无效的URL';

  @override
  String get duplicateDnsServerName => 'DNS服务器名称与已有DNS服务器重复';

  @override
  String get dnsTypeConditionDesc => '被勾选时，该条件启用。只有当一个DNS请求的类型是选中的类型时，条件成立';

  @override
  String enabledConditions(num number) {
    final intl.NumberFormat numberNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String numberString = numberNumberFormat.format(number);

    return '已启用的条件: $numberString';
  }

  @override
  String enabledSubconditions(num number) {
    final intl.NumberFormat numberNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String numberString = numberNumberFormat.format(number);

    return '已启用的子条件: $numberString';
  }

  @override
  String conditionsCount(num number) {
    final intl.NumberFormat numberNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
      
    );
    final String numberString = numberNumberFormat.format(number);

    return '$numberString 个条件';
  }

  @override
  String get showSelector => '显示选择器';

  @override
  String get hideSelector => '隐藏选择器';

  @override
  String get showHandler => '显示节点';

  @override
  String get hideHandler => '隐藏节点';

  @override
  String get restoreIAP => '恢复购买';

  @override
  String get debugLog => '开发者日志';

  @override
  String get upload => '上传';

  @override
  String get saveToDownloadFolder => '保存至下载';

  @override
  String get saveToDownloadFolderDesc => '将日志转移至下载文件夹';

  @override
  String get debugLogDesc => '如果你在使用过程中遇到了问题，你可以打开开发者日志，然后等再次遇到问题后，点击上传将开发者日志上传给我们，这将帮助我们发现BUG。（开发者日志不会被自动上传，你需要手动点击上传按钮或者将这些日志通过电报/邮箱给我们。开发者日志会包含您的网络活动, 比如使用了哪些应用和网站。我们在处理完日志后会立刻删除日志。）上传完毕后，请关闭开发者日志并删除日志文件。';

  @override
  String get clashFormatSupported => '支持Clash等格式';

  @override
  String get network => '网络类型';

  @override
  String get source => '来源';

  @override
  String get fallbackToProxy => '回退到代理';

  @override
  String get fallbackToProxySetting => '如果直连失败，使用节点重试。如果“代理选择器”存在，它选择的节点将被使用。如果它不存在，将随机选取一个正在使用的节点。';

  @override
  String get changeIpv6ToDomain => '将IPv6改为域名';

  @override
  String get changeIpv6ToDomainDesc => '如果匹配到的节点不支持IPv6，而目标地址是IPv6并且嗅探到了域名，则将目标地址改为域名。';

  @override
  String get changeDomainToIpv6 => '将域名改为IPv6';

  @override
  String get changeDomainToIpv6Desc => '如果连接目标地址是域名，则将其解析为IPv6地址。';

  @override
  String get changeDomainToIpv4 => '将域名改为IPv4';

  @override
  String get changeDomainToIpv4Desc => '如果连接目标地址是域名，则将其解析为IPv4地址。';

  @override
  String get installAsWinService => '添加VX进Windows Service';

  @override
  String get installAsWinServiceDesc => '在使用TUN前，需要将VX添加进Windows Service，点击“添加”以进行添加。';

  @override
  String get placeOnTop => '置顶';

  @override
  String get stopPlaceOnTop => '取消置顶';

  @override
  String fallbackTo(String node) {
    return '回退到 $node';
  }

  @override
  String get pingTestMethod => '延迟测试方式';

  @override
  String get pingReal => '真延迟';

  @override
  String get pingRealDesc => '拿到结果所需的时间';

  @override
  String get startOnBoot => '开机自启动';

  @override
  String get startOnBootDesc => '开机时自动运行VX';

  @override
  String get alwaysOn => '保持连接';

  @override
  String get alwaysOnDesc => '在点击“连接”后，只要不点击“断开连接”，会一直保持连接状态。';

  @override
  String get connectOnDemand => '按需连接';

  @override
  String get connectOnDemandDesc => '设备重启或网络可用后自动启动 VPN 隧道，无需打开应用。';

  @override
  String get systemManagedVpnNotice => '此 VPN 连接由 Android 系统管理。如需连接或断开，请前往 设置 > 网络和互联网 > VPN。';

  @override
  String get openVpnSettings => '打开 VPN 设置';

  @override
  String get checkAndUpdate => '检测并更新';

  @override
  String get noNewVersion => '无更新版本';

  @override
  String get enableSystemExtension => '请前往[系统设置->通用->登录项与扩展->网络扩展]并开启 VX SystemExtension';

  @override
  String get systemProxyPortSetting => '系统代理端口设定';

  @override
  String get randomPorts => '随机端口';

  @override
  String get outboundPortStrategyRandomAllPortsSameTime => '随机（所有端口同时使用）';

  @override
  String get outboundNameCannotBeDirectOrDns => '名称不能为 \"direct\" 或 \"dns\"';

  @override
  String get outboundServerAddressCannotBeEmpty => '服务器地址不能为空';

  @override
  String get outboundPortCannotBeEmpty => '端口不能为空';

  @override
  String get outboundPortHintExample => '443,444,1080-1090';

  @override
  String get outboundPortSelectStrategy => '端口选择策略';

  @override
  String get outboundPortStrategyOneSwitchByInterval => '单个（按间隔切换端口）';

  @override
  String get outboundSetIntervalOrMinMax => '请设置间隔，或最小/最大间隔';

  @override
  String get outboundPortSwitchIntervalSeconds => '间隔（秒）';

  @override
  String get outboundPortSwitchIntervalHelper => '用于固定切换间隔';

  @override
  String get outboundRequiredWhenIntervalEmpty => '未填写间隔时必填';

  @override
  String get outboundMinIntervalMustBeLeqMax => '必须 ≤ 最大间隔';

  @override
  String get outboundMinIntervalSeconds => '最小间隔（秒）';

  @override
  String get outboundMaxIntervalMustBeGeqMin => '必须 ≥ 最小间隔';

  @override
  String get outboundMaxIntervalSeconds => '最大间隔（秒）';

  @override
  String get outboundMux => 'Mux';

  @override
  String get outboundUdpOverTcp => 'UDP over TCP';

  @override
  String get outboundStream => '传输流';

  @override
  String get staticPorts => '固定端口';

  @override
  String get whenNoDomain => '没有域名时嗅探';

  @override
  String get hasNoDomain => '无域名信息';

  @override
  String get enable => '启用';

  @override
  String get disable => '禁用';

  @override
  String get checkUpdate => '检查更新';

  @override
  String get handlerCopiedSuccess => '复制节点成功！该节点已加入默认分组';

  @override
  String get hysteriaRejectQuic => 'Hysteria拒绝QUIC';

  @override
  String get disableCoreDatabase => '核心不共享数据库';

  @override
  String get disableCoreDatabaseDesc => '核心不再与UI共享数据库。如果你遇到了数据库损坏的问题，请开启此选项';

  @override
  String get syncBackup => '同步与备份';

  @override
  String get cloudSync => '云同步';

  @override
  String get cloudSyncDesc1 => '多设备间同步数据库。';

  @override
  String get cloudSyncDesc2 => '可以与谷歌FCM服务器正常通信的苹果设备和安卓设备（需装有谷歌服务）可以实现实时同步。其他设备会每5分钟同步一次。您可以点击左上角V图标手动触发同步';

  @override
  String get cloudSyncDesc3 => '同步数据会在同步后自动从云端消除，如果一直没有同步，数据在云端最多保留7天。';

  @override
  String get nodeSub => '节点/订阅';

  @override
  String get routeSetDNSSelector => '规则/集合/选择器/DNS';

  @override
  String get selectorSetting => '选择器设定';

  @override
  String selectorTestFieldsTitle(String tag) {
    return '编辑 $tag';
  }

  @override
  String get selectorTestSpeedTestSizeLabel => '测速数据量';

  @override
  String get selectorTestByteSuffix => '字节';

  @override
  String get selectorTestSpeedTestSizeHelper => '1000000 字节 = 1 MB。测速时，使用多少数据。越多，结果越准确，但是消耗高。';

  @override
  String get selectorTestSpeedTestIntervalLabel => '测速间隔';

  @override
  String get selectorTestMinutesSuffix => '分钟';

  @override
  String get selectorTestSpeedTestIntervalHelper => '多久测一次速度';

  @override
  String get selectorTestPingTestIntervalLabel => '延迟测试间隔';

  @override
  String get selectorTestPingTestIntervalHelper => '多久测一次延迟';

  @override
  String get selectorTestUnusableTestIntervalLabel => '不可用节点复测间隔';

  @override
  String get selectorTestUnusableTestIntervalHelper => '多久对筛选出的不可用节点再次检测是否恢复';

  @override
  String get selectorTestMustBeNonNegativeInteger => '必须为非负整数';

  @override
  String get selectorTestMustBeAtMostUint32Max => '不能超过 4294967295';

  @override
  String get serverKey => '服务器/密钥';

  @override
  String get lanSync => '局域网同步';

  @override
  String get sync => '同步';

  @override
  String get conditaionWarn1 => '多数情况下，域名条件和IP条件不应该同时存在。同时存在时，只有当一个请求既有域名信息，也有IP信息的时候，该规则才有可能命中。';

  @override
  String get setName => '集合名称';

  @override
  String get addSet => '添加集合';

  @override
  String get domainIpAppConditionDesc => '当请求的域名/IP/应用在下面任何集合中时，该规则匹配。';

  @override
  String get backup => '数据库备份';

  @override
  String get autoBackup => '自动备份';

  @override
  String get autoBackupDesc => '备份数据库到云端，频率为每天1次。';

  @override
  String get currentBackup => '当前备份';

  @override
  String get exportToFile => '导出到文件';

  @override
  String get uploadDb => '上传';

  @override
  String get restoreDb => '恢复';

  @override
  String get deleteCloudDb => '删除云端数据库';

  @override
  String get uploadDbSuccess => '上传数据库成功';

  @override
  String get restoreDbSuccess => '恢复数据库成功';

  @override
  String get deleteDbSuccess => '删除成功';

  @override
  String get gridView => '网格视图';

  @override
  String get listView => '列表视图';

  @override
  String get sort => '排序';

  @override
  String get clear => '清除';

  @override
  String get fallbackRetryDomain => '回退到域名';

  @override
  String get fallbackRetryDomainDesc => '如果代理连接使用IP目标，并且由于I/O超时而失败（这可能是因为DNS污染），则使用域名作为目标并重试。连接的嗅探域名将被首先使用，如果它不存在，则使用IP-to-域名。';

  @override
  String get backupPasswordDesc => '用于加密数据库。只有有这个密码的设备才可以恢复备份。密码加密储存在本地。';

  @override
  String get syncPasswordDesc => '用于加密同步数据。只有有这个密码的设备才可以同步数据。密码加密储存在本地。';

  @override
  String get addDomainIpAppSet => '添加域名/应用/IP集合';

  @override
  String get unsaved => '尚未保存';

  @override
  String get unapplied => '尚未应用';

  @override
  String get unappliedChanges => '您有未应用的更改';

  @override
  String get discard => '丢弃';

  @override
  String get applySuccess => '应用成功';

  @override
  String get applyFailed => '应用失败';

  @override
  String get rememberPasswordInMemory => '在内存中记住 sudo 密码';

  @override
  String get doNotShowAgain => '不再显示';

  @override
  String get rpmTunNotice => 'When TUN is on, Reverse Path Forwarding mode will be set to Loose(2) and reset to what it was when disconnect. You can go to the following website to learn about Reverse Path Forwarding';

  @override
  String get internalDnsDesc => '内部DNS服务器主要用于在出站拨号时解析域名，它们会从左到右依次被使用，直到解析成功为止';

  @override
  String get nodeSetDesc => '\"__node__\"为包含所有节点域名/IP的域名小集合/IP小集合。它主要被用于让VX节点测试走直连。节点域名包括它的地址和SNI';

  @override
  String get dnsNameDesc => 'DNS服务器名称可以在入站条件那里引用，以指定它所使用的节点。';

  @override
  String get directAppSetDesc => '在安卓上，直连应用集合内的应用不会经过VX（Split Tunnel）';

  @override
  String get deleteDebugLogs => '删除日志文件';

  @override
  String get conditionDesc => '当一个连接没有IP信息时，IP条件不会成立，因此规则不会匹配。同样，当一个连接没有域名信息时，域名条件不会成立，因此规则也不会匹配。';

  @override
  String get lookupEch => '查询ECH';

  @override
  String get lookupEchDesc => '如果启用且上面的ECH Config为空，则从DNS服务器查找ECH Config, 如果查询成功，使用ECH，否则不使用ECH。';

  @override
  String get adWanted => '在VX内投放广告';

  @override
  String get basicQuickDeployTitle => '双核四协议';

  @override
  String get basicQuickDeploySummary => '部署Xray、Hysteria核心和四个常用协议';

  @override
  String get basicQuickDeployDetails => '安装Xray-core以及Hysteria，并且部署以下四个入站。如果服务器已安装Xray或Hysteria，原有配置将被替换。如果服务器未开启BBR，开启BBR。';

  @override
  String get basicQuickDeployContent1 => 'Vmess 五个随机端口';

  @override
  String get basicQuickDeployContent2 => 'Shadowsocks 五个随机端口';

  @override
  String get basicQuickDeployContent3 => 'Hysteria 443端口';

  @override
  String get basicQuickDeployContent4 => 'Vless-XTLS-Vision 443端口';

  @override
  String get masqueradeQuickDeployTitle => 'Reality/XHTTP';

  @override
  String get masqueradeQuickDeploySummary => '安装Xray-core并部署Reality/XHTTP入站。如果服务器已安装Xray，原有配置将被替换。如果服务器未开启BBR，开启BBR。';

  @override
  String get masqueradeQuickDeployDetails => '安装Xray-core，并部署Reality/XHTTP入站。如果服务器已安装Xray，原有配置将被替换。如果服务器未开启BBR，开启BBR。';

  @override
  String fatalError(String error) {
    return '发生错误。请重启VX。错误: $error';
  }

  @override
  String get exit => '退出';

  @override
  String get info => '说明';

  @override
  String get selectAtleastOneSelector => '请选择至少一个选择器';

  @override
  String get addRouteMode => '添加路由模式';

  @override
  String get setNameProxyApp => 'Proxy';

  @override
  String get setNameDirectApp => 'Direct';

  @override
  String get defaultSelectorTag => '代理';

  @override
  String get selectAtleastOneNode => '请选择至少一个节点';

  @override
  String insertDefaultError(String error) {
    return '添加默认路由模式失败，请重启客户端后在路由页面点击添加。失败原因：$error';
  }

  @override
  String get pleaseSelectARoutingMode => '请选择一个路由模式';

  @override
  String get addRouteModeNotice => '点击“+”按钮添加路由模式。';

  @override
  String get freeUserCannotUseCustomRoutingMode => '免费用户无法使用自定义路由模式。请选择一个默认路由模式。您可以在路由界面添加默认路由模式。';

  @override
  String get defaultRouteModes => '默认路由模式';

  @override
  String get custom => '自定义';

  @override
  String get geositeUrlDesc => '如果为空，LoyalSoldier提供的geosite.dat将被使用';

  @override
  String get geoUrlDesc => '如果为空，LoyalSoldier提供的geoip.dat将被使用';

  @override
  String get ruBlocked => '俄罗斯屏蔽';

  @override
  String get ruBlockedDesc => '俄罗斯屏蔽的域名/IP使用代理，其他使用直连';

  @override
  String get ruBlockedAll => '俄罗斯屏蔽(全部)';

  @override
  String get ruBlockedAllDesc => '所有已知在俄罗斯被屏蔽的域名/IP使用代理，其他使用直连';

  @override
  String get dnsServerProxy => '代理DNS服务器';

  @override
  String get dnsServerDirect => '直连DNS服务器';

  @override
  String get sniffDomainForIpConnection => '如果连接使用IP目标，嗅探域名';

  @override
  String get resolveDomain => '对于目标为域名的连接，使用DNS查询IP，当每一个解析出来的IP都在指定的CIDR集合内时，该条件成立';

  @override
  String get skipSniff => '不嗅探';

  @override
  String get resolve => '解析域名';

  @override
  String get skipResolve => '不解析域名';

  @override
  String get describeTheProblem => '请描述您遇到的问题，如果您已于客服沟通，可以不填';

  @override
  String get debugLogNotAvailable => '开发者日志功能在非商店版本中不可用';

  @override
  String get useBloomFilter => '在iOS上使用Bloom Filter';

  @override
  String get useBloomFilterDesc => 'Bloom Filter可以减少内存使用，但是会有小概率（1%）的误判：不在集合中的域名可能会被误判为在集合中。';

  @override
  String get addFromClashRuleFiles => '选择Clash规则文件';

  @override
  String get selectFromInstalledApps => '选择已安装的应用';

  @override
  String get ipToDomainDesc => 'IP -> Domain是最近DNS历史记录中获取的，由于不同的域名可以解析到相同的IP，无法100%确定该连接使用此域名。';

  @override
  String get followingAiTranslated => '以下语言由AI翻译，可能不准确。';

  @override
  String get addToDefault => '添加到默认';

  @override
  String get vxCore => 'VX内核';

  @override
  String get days => '天';

  @override
  String get hours => '小时';

  @override
  String get minutes => '分钟';

  @override
  String get seconds => '秒';

  @override
  String get uptime => '已运行';

  @override
  String get outbound => '出站';

  @override
  String get overview => '综合';

  @override
  String get vxCoreConfig => 'VX内核配置';

  @override
  String get selectorDesc1 => '选择器用于挑选节点。“代理”选择器为一个特殊的选择器，它支持在节点页面里手动选择节点，其他选择器不支持此选项。';

  @override
  String get selectorDesc2 => '如果代理链里有节点，那么被选择器选中的节点将与“代理链”里的节点一起实现链式代理。[你的流量] -> [选择器选中的节点] -> [“代理链”里的第一个节点] -> ... -> [“代理链”里的最后一个节点] -> [最终目的地]';

  @override
  String get balanceStrategyDesc => '选择器会根据选择策略挑出来一个或多个节点。策略为“全部”或者“可用”时会挑出多个节点，这些节点都会被同时使用。对于一个连接，具体用哪个节点将由负载均衡决定：如果负载均衡为“随机”，那么会随机选择一个节点；如果负载均衡为“记忆”，那么同一个根域名/应用的连接会用一个节点。';

  @override
  String get inboundDesc1 => 'TUN模式将使所有网络流量由VX处理。此模式不会有DNS泄漏问题';

  @override
  String get inboundDesc2 => '系统代理模式将设置主机的代理设置。一些应用，比如浏览器，尊重这一设置所以它们的流量将由VX处理，然而，很多应用不尊重这一设置，它们的流量将不会经过VX';

  @override
  String get fakeDnsDesc => 'FakeDNS可以降低延迟';

  @override
  String get routeDesc => 'VX会根据设备语言添加一个或多个路由模式。路由模式可以在路由高级配置界面添加/删除';

  @override
  String get transportConditionMatchAllDesc => '强制入站连接使用此协议。当启用时，入站连接必须使用此协议，否则连接将失败，启用时本Multi入站只可以有一个传输层协议。当禁用时，只有在条件匹配时才会使用传输层协议，如果条件不匹配，则尝试匹配下一个传输层协议，如果没有任何传输层协议匹配，则将入站连接连接交给上一层的代理协议';

  @override
  String get transportConditionH2Desc => '以http2 preface开头的入站连接。该选项用于匹配h2协议，比如grpc或http';

  @override
  String get securityConditionMatchAllDesc => '强制入站连接使用此安全协议。当启用时，入站连接必须使用此安全协议，否则连接将失败，启用时本Multi入站只可以有一个安全层协议。当禁用时，只有在条件匹配时才会使用此安全层协议，如果条件不匹配，则尝试匹配下一个安全层协议，如果没有任何安全层协议匹配，则将入站连接连接交给上一层协议: Transport Protocol层。';

  @override
  String get allInOneQuickDeployTitle => '应有尽有';

  @override
  String get allInOneQuickDeploySummary => '安装VX核心（开源），部署多种协议';

  @override
  String get allInOneQuickDeployDetails => '安装VX核心（开源），并部署以下协议组合：(Vmess, Trojan, Anytls)x(Websocket, gRPC)x(TLS, Reality) + Hysteria。如果服务器未开启BBR，开启BBR。';

  @override
  String get addMulti => '添加Multi入站';

  @override
  String get addSingle => '添加普通入站';

  @override
  String get multiDesc => 'Multi入站可以在一个端口使用几乎所有协议。类似于Xray的回落。它支持代理层，传输层，安全层的回落，意味着你可以设置多个代理协议，传输协议和安全协议。目前不支持UDP回落，所以UDP端口只会被一个协议使用，Hysteria会被优选考虑，如果没有它，第一个支持UDP的协议会使用UDP端口。';

  @override
  String get normalInboundDesc => '普通入站类似于V2ray入站，它支持代理层的回落，可以指定多个代理协议，但它不支持传输层和安全层的回落（Multi入站支持所有层的回落）。';

  @override
  String get optional => '可不填';

  @override
  String get allInOneRealityDesc => '可不填。如果不填，将不添加Reality入站';

  @override
  String get allInOneCdnDesc => '可不填。CDN的SSL/TLS加密可以是灵活/完全。推荐使用完全，因为它会加密CDN与你的服务器之间的流量';

  @override
  String get disableOSFirewall => '禁用OS防火墙';

  @override
  String get disableOSFirewallDesc => 'VPS通常有两个防火墙，一个是OS防火墙，另一个是VPS提供商提供的防火墙。该选项只会禁用OS防火墙。很多云提供商（比如谷歌云）会默认禁用OS防火墙，但一些不会。对于那些不默认禁用OS防火墙的VPS，如果你不开启这个选项并且OS防火墙禁止以上端口的入站的话，部署的节点将无法使用，因为OS防火墙会阻止入站流量。';

  @override
  String get vxNotRunning => 'VX内核未运行';

  @override
  String get restart => '重启';

  @override
  String get stop => '停止';

  @override
  String get uninstall => '卸载';

  @override
  String get installVXCoreFirst => '请先安装VX-Core';

  @override
  String get duplicateInboundTagName => '重复的入站名称';

  @override
  String get addToNodes => '添加到节点';

  @override
  String get others => '其他';

  @override
  String get generateSelfSignedCert => '生成自签证书';

  @override
  String get certToBeProvidedToPeer => '向对方提供的证书';

  @override
  String get verifyPeerCertDesc => '用于验证对方提供的证书';

  @override
  String get issueCADesc => '用于实时签发向对方提供的证书';

  @override
  String get generatePassword => '生成密码';

  @override
  String get generate => '生成';

  @override
  String get clientOnly => '仅客户端';

  @override
  String get visionDesc => 'Vision会减少连接的特征。提高性能，特别是在 Linux上。如果你启用它，服务器也必须启用它，（该功能源自VLESS的Vision-RPRX-XTLS，和基础版Vision-RPRX-XTLS大致相同）';

  @override
  String get activeNodes => '活跃节点';

  @override
  String get activeNodesDesc => '当前正在活跃的节点，实际被使用';

  @override
  String get currentNodes => '已选节点';

  @override
  String get currentNodesDesc => '当前选中的节点';

  @override
  String get recommendedNodes => '推荐节点';

  @override
  String get connections => '连接数';

  @override
  String get realtimeRate => '速率';

  @override
  String get realtimeRateDesc => '观测到的此节点的下载速度：通过下载10KB数据所花费的时间得出。越高越好';

  @override
  String get realtimeLatency => '延迟';

  @override
  String get realtimeLatencyDesc => '观测到的此节点的实时延迟：从开始请求到收到响应所花费的时间。越低越好';

  @override
  String get realtimeSpeedSamplingInterval => '实时速率采样间隔';

  @override
  String realtimeSpeedSamplingSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒',
      one: '1 秒',
    );
    return '$_temp0';
  }

  @override
  String get download => '下载';

  @override
  String get noData => '暂无数据';

  @override
  String get autoTestNodes => '节点测试';

  @override
  String get autoTestNodesDesc => '定期测试节点并且自动测试新增节点';

  @override
  String get autoUpdateGeoFiles => '自动更新地理位置文件';

  @override
  String get autoUpdateGeoFilesDesc => '按配置的间隔自动更新地理位置文件';

  @override
  String get geoUpdateInterval => '更新间隔';

  @override
  String get geoUpdateNow => '立即更新';

  @override
  String get geoRestoreToDefault => '恢复默认';

  @override
  String get geoUpdateSuccess => '地理文件更新成功';

  @override
  String get interval => '间隔';

  @override
  String get shareWithVXclient => '分享给VX客户端';

  @override
  String get shareWithOtherClients => '分享给其他客户端';

  @override
  String get shareWithOtherClientsNotice => '可能存在不兼容问题';

  @override
  String get homeEditStandardLayout => '标准主页';

  @override
  String get homeEditCustomizableLayout => '可自定义主页';

  @override
  String get domainStrategyDesc => '影响拨号时如何解析域名。PreferIPv4: 同时查寻A和AAAA，然后尝试先IPv4，如果失败，尝试IPv6。PreferIPv6: 同时查寻A和AAAA，然后尝试先IPv6，如果失败，尝试IPv4。IPv4Only: 只查寻IPv4。IPv6Only: 只查寻IPv6。Speed: 同时查寻A和AAAA，哪个先返回结果就用哪个（可能是IPv4s或IPv6s），如果失败，则使用另一个组结果。';

  @override
  String get uotDesc => '使用TCP传输UDP（Sagernet UDP over TCP v2 协议）。服务端也必须支持它';

  @override
  String get maxConcurrency => '最大并发数';

  @override
  String get maxConnection => '最大连接数';

  @override
  String get vxNotInstalled => 'VX-core未安装';

  @override
  String get vxVersionTooLow => 'VX-core版本过低，请更新到最新版本';

  @override
  String get howToUseVX => '关于VX的使用方法，请查看我们的YouTube频道';

  @override
  String get welcome => '欢迎使用VX';

  @override
  String get sourceCodeAvailable => 'VX已完全开源，由Github Actions自动构建与发布';

  @override
  String get vxSourceCode => 'VX客户端源代码';

  @override
  String get vxCoreSourceCode => 'VX内核源代码';

  @override
  String get windowsUpdateNotice1 => '如果您从2.x.x版本更新到此应用，为了保留您的数据库和偏好设置，请关闭应用，重命名以下文件夹：';

  @override
  String get windowsUpdateNotice2 => '然后启动应用';

  @override
  String get copyPath => '复制路径';

  @override
  String get invalidFields => '表格包含无效的输入，请修改后重试';

  @override
  String get lruSizeDesc => '每个CIDR的Fake DNS记录缓存数量。';

  @override
  String get cacheDuration => '缓存时长';

  @override
  String get cacheDurationDesc => '缓存DNS记录的时长。如果为空或0，DNS记录将缓存直到它们过期';

  @override
  String get activate => '激活此设备';

  @override
  String get activateDesc => '激活后，无需登录便可使用绝大多数Pro功能（仅云同步与云备份无法使用）。每个账号每年最多激活十台设备。';

  @override
  String get activated => '已激活';

  @override
  String get myInvitationCode => '我的邀请码';

  @override
  String get myInvitationCodeDesc => '分享此邀请码给你的朋友，双方都将获得3个月Pro功能免费体验';

  @override
  String get useInvitationCode => '使用邀请码';

  @override
  String get useInvitationCodeDesc => '输入其他人的邀请码，双方都将获得3个月Pro功能免费体验！';

  @override
  String get apply => '应用';

  @override
  String get remainingTime => '剩余次数';

  @override
  String get scanQrCode => '扫描二维码';

  @override
  String get expired => '已过期';

  @override
  String get deploySuccessWarnings => '部署节点成功，但这些任务失败: ';

  @override
  String get subString => '子字符';

  @override
  String get echDomain => 'ECH域名';

  @override
  String get generateEchConfig => '生成ECH配置';

  @override
  String get echDomainDesc => '外部ClientHello SNI';

  @override
  String get restoreSuccessful => '恢复成功';

  @override
  String get pleaseUseAnotherEmail => '不支持该邮箱，请使用其他邮箱';

  @override
  String dbError(String error) {
    return '数据库出现问题: $error. 重启VX可能会有帮助。';
  }

  @override
  String get dnsRecord => '本地DNS记录';

  @override
  String get addDnsRecord => '添加本地DNS记录';

  @override
  String get internalDns => '内部DNS服务器';

  @override
  String get fallback => '回退';

  @override
  String get fallbackDesc => '如果此规则所使用的节点失败，使用以下回退。每个回退都有一些条件，只有当回退的任意一个条件成立时，回退才会被使用。';

  @override
  String get rewriteIpToDomain => '将IP重写为域名';

  @override
  String get rewriteIpToDomainDesc => '如果请求地址是IP，并且有嗅探域名，则使用嗅探域名作为请求地址。为了应对由DNS污染而导致的失败';

  @override
  String get resultIpSet => '结果IP集合';

  @override
  String get resultIpSetDesc => 'A/AAAA记录的IP不在集合内时将被丢弃';

  @override
  String get inverse => '反向';

  @override
  String get automaticallyAddFallbackDomain => '自动添加回退域名';

  @override
  String get automaticallyAddFallbackDomainDesc => '如果一个连接最初是直连，但是失败了，然后它回退到代理并成功，自动将域名添加到名为“Fallback”的域名集合中。该集合在GFW模式中被使用';

  @override
  String get fallbackTimeout => '回退超时时间';

  @override
  String get fallbackTimeoutDesc => '在有回退的情况下，如果一个连接在回退超时时间内没有收到任何返回数据，判定此连接失败，开始回退。为0即不启用功能';

  @override
  String get directDialingTimeout => '直连拨号超时时间';

  @override
  String get directDialingTimeoutHint => '直连拨号超时时间。如果在拨号超时时间内无法与目的地建立TCP连接，则连接失败。';

  @override
  String get globalDialTimeout => '节点拨号超时时间';

  @override
  String get globalDialTimeoutHint => '代理连接拨号超时时间。如果在拨号超时时间内无法与代理节点建立TCP连接，则连接失败。';

  @override
  String get reset => '重置';

  @override
  String get resetConfirmMessage => '这将重置当前数据库和偏好设置。您的现有数据将丢失。此操作无法撤销。';

  @override
  String get resetAction => '重置';

  @override
  String get resetCompletedTitle => '重置完成';

  @override
  String get resetCompletedMessage => '数据库和偏好设置已重置。请重启 VX 继续使用。';

  @override
  String get repairDbSchemaTitle => '修复数据库结构';

  @override
  String get repairDbSchemaAction => '修复数据库结构';

  @override
  String get repairDbSchemaSuccess => '数据库结构修复成功';

  @override
  String repairDbSchemaFailed(String error) {
    return '数据库结构修复失败: $error';
  }

  @override
  String resetFailed(String error) {
    return '重置失败: $error';
  }

  @override
  String get policyTimeout => '策略超时';

  @override
  String get policyTimeoutNoTimeoutHint => '-1 表示不超时';

  @override
  String policyTimeoutDefault(int seconds) {
    return '默认值：$seconds秒';
  }

  @override
  String get policyTcpIdleTimeout => 'TCP 空闲超时';

  @override
  String get policyTcpIdleTimeoutDesc => '若在此期间上行或下行均无数据，将关闭连接。';

  @override
  String get policyUdpIdleTimeout => 'UDP 空闲超时';

  @override
  String get policyUdpIdleTimeoutDesc => '若在此期间未收到上行数据，将关闭连接。';

  @override
  String get policyUpLinkOnlyTimeout => '仅上行空闲超时';

  @override
  String get policyUpLinkOnlyTimeoutDesc => '当 TCP 连接的下行数据流结束时，空闲超时切换为此值。';

  @override
  String get policyDownLinkOnlyTimeout => '仅下行空闲超时';

  @override
  String get policyDownLinkOnlyTimeoutDesc => '当 TCP 连接的上行数据流结束时，空闲超时切换为此值。';

  @override
  String get tutorial => '教程';

  @override
  String get selectGroup => '选择分组';

  @override
  String get addConcurrentDnsServer => '添加并发DNS服务器';

  @override
  String get addSerialDnsServer => '添加串行DNS服务器';

  @override
  String get concurrentDnsServerType => '并发DNS服务器';

  @override
  String get serialDnsServerType => '串行DNS服务器';

  @override
  String get useSystemDnsResolver => '使用系统DNS解析器';

  @override
  String get alwaysReturnEmptyDnsAnswer => '总是返回空DNS结果';

  @override
  String get dnsPool => '地址池';

  @override
  String get dnsServers => 'DNS服务器';

  @override
  String get invalidInterval => '无效的间隔';

  @override
  String get addresses => '地址列表';

  @override
  String get clientIp => '客户端IP';

  @override
  String get lruSize => 'LRU大小';

  @override
  String get useGoRuntimeDnsResolver => '使用 Go 运行时 DNS 解析器。';

  @override
  String get alwaysReturnEmptyDnsResponse => 'DNS 查询总是返回空响应。';

  @override
  String get dnsTypeFake => 'Fake';

  @override
  String get dnsTypePlain => 'UDP/TCP';

  @override
  String get dnsTypeDoh => 'HTTPS';

  @override
  String get dnsTypeTls => 'TLS';

  @override
  String get dnsTypeQuic => 'QUIC';

  @override
  String get dnsTypeGo => 'Go';

  @override
  String get dnsTypeEmpty => 'Empty';

  @override
  String get reservedDnsServerName => 'DNS 服务器名称 \"Hijack\" 为保留名';

  @override
  String handlersInUseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个节点',
      one: '1 个节点',
    );
    return '$_temp0';
  }

  @override
  String get selectorHandlersInUseTitle => '使用中的节点';

  @override
  String get addFreeSubscription => '添加免费订阅';

  @override
  String get resetSubscriptionLink => '重置订阅链接';

  @override
  String addFreeSubscriptionDesc(String name) {
    return '点击后，将添加名为 \"$name\" 的订阅。该订阅不保证时刻都有可用节点。订阅剩余流量每日更新。';
  }

  @override
  String get resetSubscriptionLinkDesc => '点击后，将重置订阅链接。新链接将用于获取订阅。可用于防止订阅链接泄露。';

  @override
  String get maxUsersOnly => '此功能仅限 Max 用户使用。';

  @override
  String get cnDomainsGoDirectRule => 'CN域名直连';

  @override
  String get cnIpsGoDirectRule => 'CN IP直连';

  @override
  String get cnExcludeGfwDomains => 'CN域名排除GFW';

  @override
  String get hysteriaRealm => 'Hysteria Realm';

  @override
  String get enableRealmServer => '启用 Realm 服务器';

  @override
  String get enableRealmServerDesc => '在 VX 连接时运行 Hysteria Realm 入站';

  @override
  String get configureServerSettingsFirst => '请先配置服务器设置';

  @override
  String get configureRealmSettings => '请在下方配置 Realm 设置';

  @override
  String get enterDeviceName => '请输入设备名称';

  @override
  String get configureValidRealmUrlFirst => '请先配置有效的 Realm URL';

  @override
  String get failedInboundToOutbound => '入站配置转换为出站配置失败';

  @override
  String failedConvertToUrl(String details) {
    return '转换为 URL 失败。$details';
  }

  @override
  String get realmDeviceRegistered => '设备已注册，可供其他客户端使用';

  @override
  String realmUploadFailed(String error) {
    return '上传失败：$error';
  }

  @override
  String get registerForOtherDevices => '注册供其他设备使用';

  @override
  String get registerForOtherDevicesDesc => '上传设备名称和加密的 Realm URL，以便其他 VX 客户端通过 节点 → 添加 → Realm 设备 添加此设备。请单独分享加密密码。';

  @override
  String get realmDeviceName => '设备名称';

  @override
  String get realmDeviceNameHint => '我的手机';

  @override
  String get realmDeviceNameHelper => '在其他设备的选择器中显示的名称';

  @override
  String get uploadToCloud => '上传到云端';

  @override
  String get realmServerConfiguration => '服务器配置';

  @override
  String get realmReadyToRun => '可以运行';

  @override
  String get realmNeedsSetup => '需要配置';

  @override
  String get realmAuth => '认证';

  @override
  String get realmNotSet => '未设置';

  @override
  String get realmConfigured => '已配置';

  @override
  String get realmRendezvous => '会合服务器';

  @override
  String get realmId => 'Realm ID';

  @override
  String get realmUrl => 'Realm URL';

  @override
  String get realmNotConfigured => '未配置';

  @override
  String get realmLocalPort => '本地端口';

  @override
  String get realmTlsSni => 'TLS SNI';

  @override
  String get realmObfuscation => '混淆';

  @override
  String get salamander => 'Salamander';

  @override
  String get realmSection => 'Realm';

  @override
  String get ignoreClientBandwidth => '忽略客户端带宽';

  @override
  String get realmUrlHint => 'realm://public@realm.hy2.io/random-realm-id';

  @override
  String get generateRealmUrl => '生成 Realm URL';

  @override
  String get autoConfigureRealmServer => '自动配置';

  @override
  String get realmAutoConfigured => 'Realm 服务器已配置';

  @override
  String realmAutoConfigureFailed(String error) {
    return '自动配置失败：$error';
  }

  @override
  String get realmLocalPortHelper => 'Realm 打洞的本地 UDP 端口；留空则使用随机端口';

  @override
  String get insecureRendezvous => '不安全的会合连接';

  @override
  String get insecureRendezvousDesc => '跳过会合服务器的 SNI 验证';

  @override
  String get stunServers => 'STUN 服务器';

  @override
  String get stunServersHint => 'stun.l.google.com:19302';

  @override
  String get stunTimeoutSeconds => 'STUN 超时（秒）';

  @override
  String get punchTimeoutSeconds => '打洞超时（秒）';

  @override
  String get heartbeatIntervalSeconds => '心跳间隔（秒）';

  @override
  String get ipMode => 'IP 模式';

  @override
  String get portMappingUpnp => '端口映射（UPnP/NAT-PMP）';

  @override
  String get mappingTimeoutSeconds => '映射超时（秒）';

  @override
  String get mappingLifetimeSeconds => '映射生命周期（秒）';

  @override
  String get addRealmOutbound => '添加 Realm 出站';

  @override
  String get realmDevicePicker => '设备';

  @override
  String failedLoadRealmDevices(String error) {
    return '加载 Realm 设备失败：$error';
  }

  @override
  String get noRealmDevicesFound => '未找到其他已配置 Realm 的设备';

  @override
  String get invalidRealmUrlForDevice => '所选设备的 Realm URL 无效';

  @override
  String addedRealmDevice(String name) {
    return '已添加 $name';
  }

  @override
  String get realmServer => 'Realm 服务器';

  @override
  String get realmRegistered => '已注册';

  @override
  String get realmRegistering => '注册中…';

  @override
  String realmPeersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个对端',
    );
    return '$_temp0';
  }

  @override
  String get discoveringPublicAddresses => '正在发现公网地址…';

  @override
  String get realmDevice => 'Realm 设备';

  @override
  String get realmCloudEncryptionPassword => '云端加密密码';

  @override
  String get realmCloudEncryptionPasswordHelper => '其他设备需要此密码才能解密上传的 URL。密码不会存储在服务器上。';

  @override
  String get enterRealmCloudEncryptionPassword => '请输入云端加密密码';

  @override
  String get realmDecryptPassword => '解密密码';

  @override
  String get realmDecryptPasswordDesc => '输入设备所有者分享的密码以解密 Realm URL。';

  @override
  String get realmDecryptFailed => '密码错误或加密 Realm URL 无效';
}
