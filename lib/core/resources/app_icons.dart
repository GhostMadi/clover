import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum AppIcons {
  settings(iconAndroid: Icons.settings, iconIos: Icons.settings),
  map(iconAndroid: Icons.map_rounded, iconIos: CupertinoIcons.map_fill),
  ticket(iconAndroid: Icons.confirmation_number_outlined, iconIos: CupertinoIcons.ticket),
  user(iconAndroid: Icons.person, iconIos: CupertinoIcons.person_fill),
  menu(iconAndroid: Icons.menu, iconIos: CupertinoIcons.bars),
  back(iconAndroid: Icons.arrow_back, iconIos: CupertinoIcons.back),
  addShop(iconAndroid: Icons.add, iconIos: CupertinoIcons.add_circled),
  language(iconAndroid: Icons.language, iconIos: CupertinoIcons.globe),
  theme(iconAndroid: Icons.wb_sunny_outlined, iconIos: CupertinoIcons.sun_max),
  check(iconAndroid: Icons.check, iconIos: CupertinoIcons.check_mark),
  photo(iconAndroid: Icons.photo, iconIos: CupertinoIcons.photo),
  chat(iconAndroid: Icons.chat_bubble_outline_rounded, iconIos: CupertinoIcons.chat_bubble_2),
  addPhotoAlternate(
    iconAndroid: Icons.add_photo_alternate_outlined,
    iconIos: CupertinoIcons.photo_on_rectangle,
  ),
  folder(iconAndroid: Icons.folder, iconIos: CupertinoIcons.folder),
  add(iconAndroid: Icons.add, iconIos: CupertinoIcons.add),
  delete(iconAndroid: Icons.delete_outline_outlined, iconIos: CupertinoIcons.delete),
  search(iconAndroid: Icons.search, iconIos: CupertinoIcons.search),
  more(iconAndroid: Icons.more_horiz_rounded, iconIos: CupertinoIcons.ellipsis),
  
  // Обычные (контурные)
  like(iconAndroid: Icons.favorite_border_rounded, iconIos: CupertinoIcons.heart),
  dislike(iconAndroid: Icons.thumb_down_alt_outlined, iconIos: CupertinoIcons.hand_thumbsdown),

  // ДОБАВЛЯЕМ СЮДА: Заполненные (filled) версии для лайка и дизлайка
  likeFilled(iconAndroid: Icons.favorite_rounded, iconIos: CupertinoIcons.heart_fill),
  dislikeFilled(iconAndroid: Icons.thumb_down_alt_rounded, iconIos: CupertinoIcons.hand_thumbsdown_fill),

  comment(iconAndroid: CupertinoIcons.chat_bubble_2, iconIos: CupertinoIcons.chat_bubble_2),
  send(iconAndroid: Icons.send_rounded, iconIos: CupertinoIcons.paperplane),
  bookmark(iconAndroid: Icons.bookmark_border_rounded, iconIos: CupertinoIcons.bookmark),
  bookmarkFilled(iconAndroid: Icons.bookmark_rounded, iconIos: CupertinoIcons.bookmark_fill),
  visibility(iconAndroid: Icons.visibility_outlined, iconIos: CupertinoIcons.eye),
  visibilityOff(iconAndroid: Icons.visibility_off_outlined, iconIos: CupertinoIcons.eye_slash),
  arrowDown(iconAndroid: Icons.keyboard_arrow_down_rounded, iconIos: Icons.keyboard_arrow_down_rounded),
  checkBox(iconAndroid: Icons.check_box, iconIos: CupertinoIcons.check_mark),
  checkBoxBlank(iconAndroid: Icons.check_box_outline_blank, iconIos: CupertinoIcons.square);

  final IconData iconAndroid;
  final IconData iconIos;

  const AppIcons({required this.iconAndroid, required this.iconIos});

  IconData get icon {
    if (Platform.isIOS) {
      return iconIos;
    }
    return iconAndroid;
  }
}
