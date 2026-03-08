const sharedState = window as typeof window & {
  __resxMarkLoadedModuleCount?: number;
};

sharedState.__resxMarkLoadedModuleCount =
  (sharedState.__resxMarkLoadedModuleCount || 0) + 1;

export function markLoaded(node: HTMLElement, value: string) {
  node.dataset.sharedLoaded = value;
}
