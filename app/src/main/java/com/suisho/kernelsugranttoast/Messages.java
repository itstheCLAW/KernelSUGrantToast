package com.suisho.kernelsugranttoast;

import java.util.Locale;

public class Messages {
    public static String getLocaleMessage() {
        Locale locale = Locale.getDefault();
        return switch (locale.getCountry()) {
            case "CN" ->"%s 已被授予超级用户权限";
            case "TW","HK","MO"->"已授予 %s 使用超級使用者的權限";
            default -> "%s was granted Superuser rights";
        };
    }
}
