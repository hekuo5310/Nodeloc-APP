import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// 发帖设备信息 —— 对齐 NodeLoc 官方 APP 的 mobile_source 功能。
///
/// 官方 APP（反编译 y6.java / ow0.java）按 post_source_level 分级，在创建帖子的
/// 请求体里附加以下字段，网页端帖子下方会渲染设备徽章（如「Pixel 8 Pro」）：
/// - level 1+：mobile_source_platform = "android"
/// - level 3+：mobile_source_brand   （子品牌/市场名优先，回退 Build.MANUFACTURER）
/// - level 4+：mobile_source_model   （Build.MODEL）
///
/// 本客户端为全平台应用，仅在移动端（Android / iOS）携带字段；
/// 桌面端与 Web 不发送（该功能语义为「移动端来源」标识，官方 APP 亦为移动端专属）。
class MobileSource {
  /// 官方 ow0.java 中的子品牌列表（归一化小写）
  static const Set<String> kSubBrands = {
    'iqoo',
    'redmi',
    'poco',
    'realme',
    'honor',
    'nothing',
  };

  /// 读取一次后缓存的设备三元组（platform / brand / model）
  static Map<String, String>? _cache;

  /// 清空缓存（测试用）
  static void resetCache() => _cache = null;

  /// 设备基础信息：
  /// - Android 对齐官方逻辑（brand + model）
  /// - iOS 输出友好型号名（iPhone15,2 → iPhone 15 Pro Max）
  /// - 桌面端 / Web / 读取失败返回 null（不发送任何字段）
  static Future<Map<String, String>?> readDeviceInfo() async {
    if (_cache != null) return _cache;
    if (kIsWeb) return null;
    Map<String, String>? info;
    try {
      if (Platform.isAndroid) {
        final d = await DeviceInfoPlugin().androidInfo;
        info = {
          'platform': 'android',
          'brand':
              resolveAndroidBrand(
                manufacturer: d.manufacturer,
                brand: d.brand,
                model: d.model,
                device: d.device,
                product: d.product,
              ) ??
              '',
          'model': d.model.trim(),
        };
      } else if (Platform.isIOS) {
        final d = await DeviceInfoPlugin().iosInfo;
        info = {
          'platform': 'ios',
          'brand': 'Apple',
          'model': friendlyIOSModelName(d.utsname.machine),
        };
      }
    } catch (_) {
      info = null;
    }
    _cache = info;
    return info;
  }

  /// Android 品牌解析（对齐官方 ow0.a() 的意图）。
  ///
  /// 官方优先读市场名系统属性（ro.product.marketname / ro.vivo.market.name 等）
  /// 并在归一化后精确匹配子品牌列表，未命中回退 Build.MANUFACTURER。
  /// Flutter 侧无法读取系统属性，等价实现为在
  /// brand / manufacturer / model / device / product 中扫描子品牌关键词
  /// （Redmi、POCO、iQOO 等机型的 Build.BRAND / Build.MODEL 本身就含子品牌字样），
  /// 命中即返回该子品牌；未命中回退 manufacturer —— 与官方最终回退一致。
  static String? resolveAndroidBrand({
    required String manufacturer,
    String brand = '',
    String model = '',
    String device = '',
    String product = '',
  }) {
    final mfr = manufacturer.trim();
    final haystack = [brand, mfr, model, device, product]
        .map((s) => _normalize(s))
        .join('\n');
    for (final sub in kSubBrands) {
      // 六个子品牌词均不会是其它厂商标识的子串，contains 匹配安全
      if (haystack.contains(sub)) return sub;
    }
    final b = brand.trim();
    if (mfr.isNotEmpty) return mfr;
    if (b.isNotEmpty) return b;
    return null;
  }

  /// 按等级生成发帖附加字段（level 语义对齐官方 post_source_level）：
  /// 0 = 关闭；1 = 仅平台；3 = 平台 + 品牌；4 = 平台 + 品牌 + 型号。
  /// 空值字段自动省略；全部为空时返回 null。
  static Map<String, String>? buildFields({
    required int level,
    String? platform,
    String? brand,
    String? model,
  }) {
    if (level <= 0) return null;
    final fields = <String, String>{};
    void put(String key, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) fields[key] = v;
    }

    put('mobile_source_platform', platform);
    if (level >= 3) put('mobile_source_brand', brand);
    if (level >= 4) put('mobile_source_model', model);
    return fields.isEmpty ? null : fields;
  }

  /// 发帖入口：按用户等级返回设备信息字段（桌面端 / 关闭 / 失败返回 null）
  static Future<Map<String, String>?> fieldsForLevel(int level) async {
    if (level <= 0) return null;
    final info = await readDeviceInfo();
    if (info == null) return null;
    return buildFields(
      level: level,
      platform: info['platform'],
      brand: info['brand'],
      model: info['model'],
    );
  }

  /// 当前设备的徽章预览文本（设置页示例用；桌面端返回 null）
  static Future<String?> previewBadge(int level) async {
    final f = await fieldsForLevel(level);
    if (f == null) return null;
    return f['mobile_source_model'] ??
        f['mobile_source_brand'] ??
        f['mobile_source_platform'];
  }

  /// 小写并去除全部空白（对齐官方 normalize 逻辑）
  static String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(' ', '');

  // -------------------------------------------------------------- iOS 型号

  /// iOS utsname.machine 标识（如 iPhone15,2）→ 友好型号名。
  /// 未收录的新机型回退为泛称（iPhone / iPad / iPod touch）。
  static String friendlyIOSModelName(String machine) {
    final m = machine.trim();
    final mapped = _iosMachineNames[m];
    if (mapped != null) return mapped;
    if (m.startsWith('iPhone')) return 'iPhone';
    if (m.startsWith('iPad')) return 'iPad';
    if (m.startsWith('iPod')) return 'iPod touch';
    return m;
  }

  /// 常见 iPhone / iPad 硬件标识 → 营销名称
  static const Map<String, String> _iosMachineNames = {
    // iPhone（XR 起）
    'iPhone11,8': 'iPhone XR',
    'iPhone12,1': 'iPhone 11',
    'iPhone12,3': 'iPhone 11 Pro',
    'iPhone12,5': 'iPhone 11 Pro Max',
    'iPhone12,8': 'iPhone SE (2nd gen)',
    'iPhone13,1': 'iPhone 12 mini',
    'iPhone13,2': 'iPhone 12',
    'iPhone13,3': 'iPhone 12 Pro',
    'iPhone13,4': 'iPhone 12 Pro Max',
    'iPhone14,2': 'iPhone 13 Pro',
    'iPhone14,3': 'iPhone 13 Pro Max',
    'iPhone14,4': 'iPhone 13 mini',
    'iPhone14,5': 'iPhone 13',
    'iPhone14,6': 'iPhone SE (3rd gen)',
    'iPhone14,7': 'iPhone 14',
    'iPhone14,8': 'iPhone 14 Plus',
    'iPhone15,2': 'iPhone 14 Pro',
    'iPhone15,3': 'iPhone 14 Pro Max',
    'iPhone15,4': 'iPhone 15',
    'iPhone16,1': 'iPhone 15 Pro',
    'iPhone16,2': 'iPhone 15 Pro Max',
    'iPhone17,1': 'iPhone 16 Pro',
    'iPhone17,2': 'iPhone 16 Pro Max',
    'iPhone17,3': 'iPhone 16',
    'iPhone17,4': 'iPhone 16 Plus',
    'iPhone17,5': 'iPhone 16e',
    // iPad Pro（M 系列）
    'iPad13,4': 'iPad Pro 11 (M1)',
    'iPad13,5': 'iPad Pro 11 (M1)',
    'iPad13,6': 'iPad Pro 11 (M1)',
    'iPad13,7': 'iPad Pro 11 (M1)',
    'iPad13,8': 'iPad Pro 12.9 (M1)',
    'iPad13,9': 'iPad Pro 12.9 (M1)',
    'iPad13,10': 'iPad Pro 12.9 (M1)',
    'iPad13,11': 'iPad Pro 12.9 (M1)',
    'iPad14,1': 'iPad Pro 11 (M2)',
    'iPad14,2': 'iPad Pro 11 (M2)',
    'iPad14,3': 'iPad Pro 12.9 (M2)',
    'iPad14,4': 'iPad Pro 12.9 (M2)',
    'iPad16,3': 'iPad Pro 11 (M4)',
    'iPad16,4': 'iPad Pro 11 (M4)',
    'iPad16,5': 'iPad Pro 13 (M4)',
    'iPad16,6': 'iPad Pro 13 (M4)',
  };
}
