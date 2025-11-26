export function getOrRaise<T>(
  opt: T | undefined,
  name: string,
  expectedType: string,
  message?: string
): T;

export function getString(
  form: FormData,
  name: string,
  allowEmptyString?: boolean
): string | undefined;

export function getInt(form: FormData, name: string): number | undefined;
export function getFloat(form: FormData, name: string): number | undefined;
export function getBool(form: FormData, name: string): boolean | undefined;

export function getStringArray(form: FormData, name: string): string[];
export function getIntArray(form: FormData, name: string): number[];
export function getFloatArray(form: FormData, name: string): number[];
export function getBoolArray(form: FormData, name: string): boolean[];

export function getCustom<T>(
  form: FormData,
  name: string,
  decoder: (value: FormDataEntryValue | null) => T
): T;

export type ExpectResult<T> =
  | { TAG: "Ok"; _0: T }
  | { TAG: "Error"; _0: string };

export function expectCustom<T>(
  form: FormData,
  name: string,
  decoder: (value: FormDataEntryValue | null) => ExpectResult<T>
): T;

export function expectString(
  form: FormData,
  name: string,
  message?: string
): string;
export function expectInt(form: FormData, name: string, message?: string): number;
export function expectFloat(
  form: FormData,
  name: string,
  message?: string
): number;
export function expectBool(
  form: FormData,
  name: string,
  message?: string
): boolean;

export function expectCheckbox(form: FormData, name: string): boolean;
export function expectDate(form: FormData, name: string): Date;

