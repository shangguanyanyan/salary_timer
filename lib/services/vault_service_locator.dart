import 'vault_service.dart';

/// 提供全局访问VaultService的单例类
class VaultServiceLocator {
  static final VaultServiceLocator instance = VaultServiceLocator._internal();

  VaultService? _vaultService;

  // 私有构造函数
  VaultServiceLocator._internal();

  // 获取VaultService实例
  VaultService? get vaultService => _vaultService;

  // 设置VaultService实例
  set vaultService(VaultService? service) {
    _vaultService = service;
  }
}
