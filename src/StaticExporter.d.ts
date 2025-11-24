export declare const debugging: boolean;
export function debug(message: string): void;
export function log(message: string): void;

export function run(
  server: { hostname: string; port: number; stop: (force?: boolean) => void },
  urls: string[],
): Promise<void>;

