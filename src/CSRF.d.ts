export const tokenInputName: string;

export function getTokenFromHeaders(headers: Headers): string | undefined;
export function getTokenFromRequest(request: Request): Promise<string | undefined>;

export function getSecret(): string | undefined;
export function generateToken(): string;
export function verifyRequest(request: Request): Promise<boolean>;

