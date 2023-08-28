#define NoPrompte           0x00000001          && do not prompt for file name
#define	UseFileName         0x00000002          && use file name set by SetDefaultFileName else use document name
#define	Concatenate         0x00000004          && concatenate files, do not override 
#define	EmbedFonts          0x00000010          && embed fonts used in the input document 
#define	BroadcastMessages   0x00000020          && broadcast PDF events 
#define	PrintWatermark      0x00000040          && add watermark to each page
#define MultilingualSupport 0x00000080          && activate multi-lingual support
#define	EncryptDocument     0x00000100          && encrypt resulting document
#define	SendByEmail         0x00000800          && send by email
#define	LinearizeForWeb     0x00008000          && web optimisation (Linearization)
#define	PostProcessing      0x00010000          && post process file using specified application
#define	JPegLevelLow        0x00020000          && Low JPeg compression
#define	JPegLevelMedium     0x00040000          && Medium JPeg compression
#define JPegLevelHigh       0x00060000          && High JPeg compression
#define	Colors2GrayScale    0x00080000          && convert colors to gray scale
#define	ConvertHyperlinks   0x00100000          && automatic hyperlink conversion
#define	EmbedStandardFonts  0x00200000          && embed standard fonts such as Arial, Times, ...
#define	EmbedLicensedFonts  0x00400000          && embed fonts requiring a license
#define	Color256Compression 0x00080000          && activate 256 color compression
#define	EmbedSimulatedFonts 0x01000000          && embed bold and italic simulated fonts
#define	SendToCreator       0x02000000          && page by page option
#define	HTMLExport          0x04000000          && export in html format
#define	RTFExport           0x08000000          && export in rtf format
#define	JPEGExport          0x10000000          && export in jpeg format
#define	CCITTCompression    0x20000000          && activate CCITT compression
#define	EncryptDocument128  0x40000000          && encrypt resulting document by 128 bits enc
#define	AutoCompression     0x80000000          && activate automatic image compression

