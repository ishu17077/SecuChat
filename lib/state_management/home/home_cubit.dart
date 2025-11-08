import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/state_management/home/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final IUserService _userService;
  final ILocalCache _localCache;
  HomeCubit(this._userService, this._localCache) : super(HomeInitial());

  Future<User> connect() async {
    final userJson = _localCache.fetch("USER");
    userJson["last_seen"] = DateTime.now();
    userJson["active"] = true;

    final user = User.fromJSON(userJson);
    return user;
  }

  Future<void> activeUsers(User user) async {
    emit(HomeLoading());
    final onlineUsers = await _userService.online();

    onlineUsers.removeWhere((element) => element.id == user.id);
    emit(HomeSuccess(onlineUsers));
  }
}
