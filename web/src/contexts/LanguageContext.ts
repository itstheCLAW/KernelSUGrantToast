import { createContext } from "react";
import type SupportedLangs from "@/locales/SupportedLangs";

export const LanguageContext = createContext<keyof typeof SupportedLangs>("en-US");