type domProps = {
  children?: JsxU.element,
  /* accessibility */
  /* https://www.w3.org/TR/wai-aria-1.1/ */
  /* https://accessibilityresources.org/<aria-tag> is a great resource for these */
  @as("aria-current")
  ariaCurrent?: [#page | #step | #location | #date | #time | #"true" | #"false"],
  @as("aria-details")
  ariaDetails?: string,
  @as("aria-disabled")
  ariaDisabled?: bool,
  @as("aria-hidden")
  ariaHidden?: bool,
  @as("aria-invalid") ariaInvalid?: [#grammar | #"false" | #spelling | #"true"],
  @as("aria-keyshortcuts")
  ariaKeyshortcuts?: string,
  @as("aria-label")
  ariaLabel?: string,
  @as("aria-roledescription")
  ariaRoledescription?: string,
  /* Widget Attributes */
  @as("aria-autocomplete") ariaAutocomplete?: [#inline | #list | #both | #none],
  /* https://www.w3.org/TR/wai-aria-1.1/#valuetype_tristate */
  @as("aria-checked")
  ariaChecked?: [#"true" | #"false" | #mixed],
  @as("aria-expanded")
  ariaExpanded?: bool,
  @as("aria-haspopup")
  ariaHaspopup?: [#menu | #listbox | #tree | #grid | #dialog | #"true" | #"false"],
  @as("aria-level")
  ariaLevel?: int,
  @as("aria-modal")
  ariaModal?: bool,
  @as("aria-multiline")
  ariaMultiline?: bool,
  @as("aria-multiselectable")
  ariaMultiselectable?: bool,
  @as("aria-orientation") ariaOrientation?: [#horizontal | #vertical | #undefined],
  @as("aria-placeholder")
  ariaPlaceholder?: string,
  /* https://www.w3.org/TR/wai-aria-1.1/#valuetype_tristate */
  @as("aria-pressed") ariaPressed?: [#"true" | #"false" | #mixed],
  @as("aria-readonly")
  ariaReadonly?: bool,
  @as("aria-required")
  ariaRequired?: bool,
  @as("aria-selected")
  ariaSelected?: bool,
  @as("aria-sort")
  ariaSort?: string,
  @as("aria-valuemax")
  ariaValuemax?: float,
  @as("aria-valuemin")
  ariaValuemin?: float,
  @as("aria-valuenow")
  ariaValuenow?: float,
  @as("aria-valuetext")
  ariaValuetext?: string,
  /* Live Region Attributes */
  @as("aria-atomic")
  ariaAtomic?: bool,
  @as("aria-busy")
  ariaBusy?: bool,
  @as("aria-live") ariaLive?: [#off | #polite | #assertive | #rude],
  @as("aria-relevant")
  ariaRelevant?: string,
  /* Drag-and-Drop Attributes */
  @as("aria-dropeffect") ariaDropeffect?: [#copy | #move | #link | #execute | #popup | #none],
  @as("aria-grabbed")
  ariaGrabbed?: bool,
  /* Relationship Attributes */
  @as("aria-activedescendant")
  ariaActivedescendant?: string,
  @as("aria-colcount")
  ariaColcount?: int,
  @as("aria-colindex")
  ariaColindex?: int,
  @as("aria-colspan")
  ariaColspan?: int,
  @as("aria-controls")
  ariaControls?: string,
  @as("aria-describedby")
  ariaDescribedby?: string,
  @as("aria-errormessage")
  ariaErrormessage?: string,
  @as("aria-flowto")
  ariaFlowto?: string,
  @as("aria-labelledby")
  ariaLabelledby?: string,
  @as("aria-owns")
  ariaOwns?: string,
  @as("aria-posinset")
  ariaPosinset?: int,
  @as("aria-rowcount")
  ariaRowcount?: int,
  @as("aria-rowindex")
  ariaRowindex?: int,
  @as("aria-rowspan")
  ariaRowspan?: int,
  @as("aria-setsize")
  ariaSetsize?: int,
  /* react textarea/input */
  defaultChecked?: bool,
  defaultValue?: string,
  /* global html attributes */
  accessKey?: string,
  className?: string /* substitute for "class" */,
  contentEditable?: bool,
  contextMenu?: string,
  @as("data-testid") dataTestId?: string,
  dir?: string /* "ltr", "rtl" or "auto" */,
  draggable?: bool,
  hidden?: bool,
  id?: string,
  lang?: string,
  role?: string /* ARIA role */,
  style?: string,
  spellCheck?: bool,
  tabIndex?: int,
  title?: string,
  /* html5 microdata */
  itemID?: string,
  itemProp?: string,
  itemRef?: string,
  itemScope?: bool,
  itemType?: string /* uri */,
  /* tag-specific html attributes */
  accept?: string,
  acceptCharset?: string,
  action?: string /* uri */,
  allowFullScreen?: bool,
  alt?: string,
  @as("as")
  as_?: string,
  async?: bool,
  autoComplete?: string /* has a fixed, but large-ish, set of possible values */,
  autoCapitalize?: string /* Mobile Safari specific */,
  autoFocus?: bool,
  autoPlay?: bool,
  challenge?: string,
  charSet?: string,
  checked?: bool,
  cite?: string /* uri */,
  crossOrigin?: string /* anonymous, use-credentials */,
  cols?: int,
  colSpan?: int,
  content?: string,
  controls?: bool,
  coords?: string /* set of values specifying the coordinates of a region */,
  data?: string /* uri */,
  dateTime?: string /* "valid date string with optional time" */,
  default?: bool,
  defer?: bool,
  disabled?: bool,
  download?: string /* should really be either a boolean, signifying presence, or a string */,
  encType?: string /* "application/x-www-form-urlencoded", "multipart/form-data" or "text/plain" */,
  form?: string,
  formAction?: string /* uri */,
  formTarget?: string /* "_blank", "_self", etc. */,
  formMethod?: string /* "post", "get", "put" */,
  headers?: string,
  height?: string /* in html5 this can only be a number, but in html4 it can ba a percentage as well */,
  high?: int,
  href?: string /* uri */,
  hrefLang?: string,
  htmlFor?: string /* substitute for "for" */,
  httpEquiv?: string /* has a fixed set of possible values */,
  icon?: string /* uri? */,
  inputMode?: string /* "verbatim", "latin", "numeric", etc. */,
  integrity?: string,
  keyType?: string,
  kind?: string /* has a fixed set of possible values */,
  label?: string,
  list?: string,
  loading?: [#"lazy" | #eager],
  loop?: bool,
  low?: int,
  manifest?: string /* uri */,
  max?: string /* should be int or Js.Date.t */,
  maxLength?: int,
  media?: string /* a valid media query */,
  mediaGroup?: string,
  method?: string /* "post" or "get" */,
  min?: string,
  minLength?: int,
  multiple?: bool,
  muted?: bool,
  name?: string,
  nonce?: string,
  noValidate?: bool,
  @as("open")
  open_?: bool /* use this one. Previous one is deprecated */,
  optimum?: int,
  pattern?: string /* valid Js RegExp */,
  placeholder?: string,
  playsInline?: bool,
  poster?: string /* uri */,
  preload?: string /* "none", "metadata" or "auto" (and "" as a synonym for "auto") */,
  radioGroup?: string,
  readOnly?: bool,
  rel?: string /* a space- or comma-separated (depending on the element) list of a fixed set of "link types" */,
  required?: bool,
  reversed?: bool,
  rows?: int,
  rowSpan?: int,
  sandbox?: string /* has a fixed set of possible values */,
  scope?: string /* has a fixed set of possible values */,
  scoped?: bool,
  scrolling?: string /* html4 only, "auto", "yes" or "no" */,
  /* seamless - supported by React, but removed from the html5 spec */
  selected?: bool,
  shape?: string,
  size?: int,
  sizes?: string,
  span?: int,
  src?: string /* uri */,
  srcDoc?: string,
  srcLang?: string,
  srcSet?: string,
  start?: int,
  step?: float,
  summary?: string /* deprecated */,
  target?: string,
  @as("type")
  type_?: string /* has a fixed but large-ish set of possible values */ /* use this one. Previous one is deprecated */,
  useMap?: string,
  value?: string,
  width?: string /* in html5 this can only be a number, but in html4 it can ba a percentage as well */,
  wrap?: string /* "hard" or "soft" */,
  /* Clipboard events */
  onCopy?: string,
  onCut?: string,
  onPaste?: string,
  /* Composition events */
  onCompositionEnd?: string,
  onCompositionStart?: string,
  onCompositionUpdate?: string,
  /* Keyboard events */
  onKeyDown?: string,
  onKeyPress?: string,
  onKeyUp?: string,
  /* Focus events */
  onFocus?: string,
  onBlur?: string,
  /* Form events */
  onBeforeInput?: string,
  onChange?: string,
  onInput?: string,
  onReset?: string,
  onSubmit?: string,
  onInvalid?: string,
  /* Mouse events */
  onClick?: string,
  onContextMenu?: string,
  onDoubleClick?: string,
  onDrag?: string,
  onDragEnd?: string,
  onDragEnter?: string,
  onDragExit?: string,
  onDragLeave?: string,
  onDragOver?: string,
  onDragStart?: string,
  onDrop?: string,
  onMouseDown?: string,
  onMouseEnter?: string,
  onMouseLeave?: string,
  onMouseMove?: string,
  onMouseOut?: string,
  onMouseOver?: string,
  onMouseUp?: string,
  /* Selection events */
  onSelect?: string,
  /* Touch events */
  onTouchCancel?: string,
  onTouchEnd?: string,
  onTouchMove?: string,
  onTouchStart?: string,
  // Pointer events
  onPointerOver?: string,
  onPointerEnter?: string,
  onPointerDown?: string,
  onPointerMove?: string,
  onPointerUp?: string,
  onPointerCancel?: string,
  onPointerOut?: string,
  onPointerLeave?: string,
  onGotPointerCapture?: string,
  onLostPointerCapture?: string,
  /* UI events */
  onScroll?: string,
  /* Wheel events */
  onWheel?: string,
  /* Media events */
  onAbort?: string,
  onCanPlay?: string,
  onCanPlayThrough?: string,
  onDurationChange?: string,
  onEmptied?: string,
  onEncrypted?: string,
  onEnded?: string,
  onError?: string,
  onLoadedData?: string,
  onLoadedMetadata?: string,
  onLoadStart?: string,
  onPause?: string,
  onPlay?: string,
  onPlaying?: string,
  onProgress?: string,
  onRateChange?: string,
  onSeeked?: string,
  onSeeking?: string,
  onStalled?: string,
  onSuspend?: string,
  onTimeUpdate?: string,
  onVolumeChange?: string,
  onWaiting?: string,
  /* Image events */
  onLoad?: string /* duplicate */ /* ~onError: ReactEvent.Image.t => unit=?, */,
  /* Animation events */
  onAnimationStart?: string,
  onAnimationEnd?: string,
  onAnimationIteration?: string,
  /* Transition events */
  onTransitionEnd?: string,
  /* svg */
  accentHeight?: string,
  accumulate?: string,
  additive?: string,
  alignmentBaseline?: string,
  allowReorder?: string,
  alphabetic?: string,
  amplitude?: string,
  arabicForm?: string,
  ascent?: string,
  attributeName?: string,
  attributeType?: string,
  autoReverse?: string,
  azimuth?: string,
  baseFrequency?: string,
  baseProfile?: string,
  baselineShift?: string,
  bbox?: string,
  begin?: string,
  @deprecated("Please use begin")
  begin_?: string,
  bias?: string,
  by?: string,
  calcMode?: string,
  capHeight?: string,
  clip?: string,
  clipPath?: string,
  clipPathUnits?: string,
  clipRule?: string,
  colorInterpolation?: string,
  colorInterpolationFilters?: string,
  colorProfile?: string,
  colorRendering?: string,
  contentScriptType?: string,
  contentStyleType?: string,
  cursor?: string,
  cx?: string,
  cy?: string,
  d?: string,
  decelerate?: string,
  descent?: string,
  diffuseConstant?: string,
  direction?: string,
  display?: string,
  divisor?: string,
  dominantBaseline?: string,
  dur?: string,
  dx?: string,
  dy?: string,
  edgeMode?: string,
  elevation?: string,
  enableBackground?: string,
  end?: string,
  @deprecated("Please use end")
  end_?: string,
  exponent?: string,
  externalResourcesRequired?: string,
  fill?: string,
  fillOpacity?: string,
  fillRule?: string,
  filter?: string,
  filterRes?: string,
  filterUnits?: string,
  floodColor?: string,
  floodOpacity?: string,
  focusable?: string,
  fontFamily?: string,
  fontSize?: string,
  fontSizeAdjust?: string,
  fontStretch?: string,
  fontStyle?: string,
  fontVariant?: string,
  fontWeight?: string,
  fomat?: string,
  from?: string,
  fx?: string,
  fy?: string,
  g1?: string,
  g2?: string,
  glyphName?: string,
  glyphOrientationHorizontal?: string,
  glyphOrientationVertical?: string,
  glyphRef?: string,
  gradientTransform?: string,
  gradientUnits?: string,
  hanging?: string,
  horizAdvX?: string,
  horizOriginX?: string,
  ideographic?: string,
  imageRendering?: string,
  @as("in")
  in_?: string /* use this one. Previous one is deprecated */,
  in2?: string,
  intercept?: string,
  k?: string,
  k1?: string,
  k2?: string,
  k3?: string,
  k4?: string,
  kernelMatrix?: string,
  kernelUnitLength?: string,
  kerning?: string,
  keyPoints?: string,
  keySplines?: string,
  keyTimes?: string,
  lengthAdjust?: string,
  letterSpacing?: string,
  lightingColor?: string,
  limitingConeAngle?: string,
  local?: string,
  markerEnd?: string,
  markerHeight?: string,
  markerMid?: string,
  markerStart?: string,
  markerUnits?: string,
  markerWidth?: string,
  mask?: string,
  maskContentUnits?: string,
  maskUnits?: string,
  mathematical?: string,
  mode?: string,
  numOctaves?: string,
  offset?: string,
  opacity?: string,
  operator?: string,
  order?: string,
  orient?: string,
  orientation?: string,
  origin?: string,
  overflow?: string,
  overflowX?: string,
  overflowY?: string,
  overlinePosition?: string,
  overlineThickness?: string,
  paintOrder?: string,
  panose1?: string,
  pathLength?: string,
  patternContentUnits?: string,
  patternTransform?: string,
  patternUnits?: string,
  pointerEvents?: string,
  points?: string,
  pointsAtX?: string,
  pointsAtY?: string,
  pointsAtZ?: string,
  preserveAlpha?: string,
  preserveAspectRatio?: string,
  primitiveUnits?: string,
  r?: string,
  radius?: string,
  refX?: string,
  refY?: string,
  renderingIntent?: string,
  repeatCount?: string,
  repeatDur?: string,
  requiredExtensions?: string,
  requiredFeatures?: string,
  restart?: string,
  result?: string,
  rotate?: string,
  rx?: string,
  ry?: string,
  scale?: string,
  seed?: string,
  shapeRendering?: string,
  slope?: string,
  spacing?: string,
  specularConstant?: string,
  specularExponent?: string,
  speed?: string,
  spreadMethod?: string,
  startOffset?: string,
  stdDeviation?: string,
  stemh?: string,
  stemv?: string,
  stitchTiles?: string,
  stopColor?: string,
  stopOpacity?: string,
  strikethroughPosition?: string,
  strikethroughThickness?: string,
  string?: string,
  stroke?: string,
  strokeDasharray?: string,
  strokeDashoffset?: string,
  strokeLinecap?: string,
  strokeLinejoin?: string,
  strokeMiterlimit?: string,
  strokeOpacity?: string,
  strokeWidth?: string,
  surfaceScale?: string,
  systemLanguage?: string,
  tableValues?: string,
  targetX?: string,
  targetY?: string,
  textAnchor?: string,
  textDecoration?: string,
  textLength?: string,
  textRendering?: string,
  to?: string,
  @deprecated("Please use to")
  to_?: string,
  transform?: string,
  u1?: string,
  u2?: string,
  underlinePosition?: string,
  underlineThickness?: string,
  unicode?: string,
  unicodeBidi?: string,
  unicodeRange?: string,
  unitsPerEm?: string,
  vAlphabetic?: string,
  vHanging?: string,
  vIdeographic?: string,
  vMathematical?: string,
  values?: string,
  vectorEffect?: string,
  version?: string,
  vertAdvX?: string,
  vertAdvY?: string,
  vertOriginX?: string,
  vertOriginY?: string,
  viewBox?: string,
  viewTarget?: string,
  visibility?: string,
  /* width::string? => */
  widths?: string,
  wordSpacing?: string,
  writingMode?: string,
  x?: string,
  x1?: string,
  x2?: string,
  xChannelSelector?: string,
  xHeight?: string,
  xlinkActuate?: string,
  xlinkArcrole?: string,
  xlinkHref?: string,
  xlinkRole?: string,
  xlinkShow?: string,
  xlinkTitle?: string,
  xlinkType?: string,
  xmlns?: string,
  xmlnsXlink?: string,
  xmlBase?: string,
  xmlLang?: string,
  xmlSpace?: string,
  y?: string,
  y1?: string,
  y2?: string,
  yChannelSelector?: string,
  z?: string,
  zoomAndPan?: string,
  /* RDFa */
  about?: string,
  datatype?: string,
  inlist?: string,
  prefix?: string,
  property?: string,
  resource?: string,
  typeof?: string,
  vocab?: string,
  dangerouslySetInnerHTML?: {"__html": string},
  /* HTMX stuff */
  ...Htmx.htmxProps,
  /* ResX stuff */
  ...ResX__DOM.domProps,
}
