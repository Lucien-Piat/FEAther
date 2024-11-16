# -----------------------------------------
# Project: FEA-ther (Functional Enrichment Analysis Tool)
# Author: Lucien Piat
# Affiliation: Rouen Normandie University
# Date: 04/10/2024
# Description: Custom theme made for the FEAther project
# -----------------------------------------
library(dashboardthemes)
customTheme <- shinyDashboardThemeDIY(
  ### general
  appFontFamily = "Helvetica",
  appFontColor = "rgb(31,59,100)",
  primaryFontColor = "rgb(31,59,100)",
  infoFontColor = "rgb(31,59,100)",
  successFontColor = "rgb(31,59,100)",
  warningFontColor = "rgb(31,59,100)",
  dangerFontColor = "rgb(31,59,100)",
  bodyBackColor = "rgb(189,196,209)",

  ### header
  logoBackColor = "rgb(35,114,117)",
  headerButtonBackColor = "rgb(34,117,53)",
  headerButtonIconColor = "rgb(255,255,255)",
  headerButtonBackColorHover = "rgb(209,219,39)",
  headerButtonIconColorHover = "rgb(0,0,0)",
  headerBackColor = "rgb(238,238,238)",
  headerBoxShadowColor = "#aaaaaa",
  headerBoxShadowSize = "2px 2px 2px",

  ### sidebar
  sidebarBackColor = "rgb(64,147,83)",
  sidebarPadding = 0,
  sidebarMenuBackColor = "rgb(34,117,53)",
  sidebarMenuPadding = 0,
  sidebarMenuBorderRadius = 0,
  sidebarShadowRadius = "3px 5px 5px",
  sidebarShadowColor = "#aaaaaa",
  sidebarUserTextColor = "rgb(255,255,255)",
  sidebarSearchBackColor = "rgb(55,72,80)",
  sidebarSearchIconColor = "rgb(153,153,153)",
  sidebarSearchBorderColor = "rgb(55,72,80)",
  sidebarTabTextColor = "rgb(255,255,255)",
  sidebarTabTextSize = 18,
  sidebarTabBorderStyle = "none none solid none",
  sidebarTabBorderColor = "rgb(100,60,100)",
  sidebarTabBorderWidth = 3,
  sidebarTabBackColorSelected = "rgb(209,219,39)",
  sidebarTabTextColorSelected = "rgb(31,59,100)",
  sidebarTabRadiusSelected = "30px 30px 30px 30px",
  sidebarTabBackColorHover = "rgb(209,219,39)",
  sidebarTabTextColorHover = "rgb(31,59,100)",
  sidebarTabBorderStyleHover = "none none solid none",
  sidebarTabBorderColorHover = "rgb(100,60,100)",
  sidebarTabBorderWidthHover = 3,
  sidebarTabRadiusHover = "30px 30px 30px 30px",

  ### boxes
  boxBackColor = "rgb(255,255,255)",
  boxBorderRadius = 5,
  boxShadowSize = "0px 5px 5px",
  boxShadowColor = "rgba(0,0,0,.1)",
  boxTitleSize = 16,
  boxDefaultColor = "rgb(210,214,220)",
  boxPrimaryColor = "rgba(44,222,235,1)",
  boxInfoColor = "rgb(210,214,220)",
  boxSuccessColor = "rgba(0,255,213,1)",
  boxWarningColor = "rgb(244,156,104)",
  boxDangerColor = "rgb(255,88,55)",
  tabBoxTabColor = "rgb(255,255,255)",
  tabBoxTabTextSize = 14,
  tabBoxTabTextColor = "rgb(0,0,0)",
  tabBoxTabTextColorSelected = "rgb(0,0,0)",
  tabBoxBackColor = "rgb(255,255,255)",
  tabBoxHighlightColor = "rgba(44,222,235,1)",
  tabBoxBorderRadius = 5,

  ### inputs
  buttonBackColor = "rgb(245,245,245)",
  buttonTextColor = "rgb(31,59,100)",
  buttonBorderColor = "rgb(31,59,100)",
  buttonBorderRadius = 5,
  buttonBackColorHover = "rgb(235,235,235)",
  buttonTextColorHover = "rgb(100,100,100)",
  buttonBorderColorHover = "rgb(200,200,200)",
  textboxBackColor = "rgb(255,255,255)",
  textboxBorderColor = "rgb(200,200,200)",
  textboxBorderRadius = 5,
  textboxBackColorSelect = "rgb(245,245,245)",
  textboxBorderColorSelect = "rgb(200,200,200)",

  ### tables
  tableBackColor = "rgb(144,227,153)",
  tableBorderColor = "rgb(114,197,133)",
  tableBorderTopSize = 1,
  tableBorderRowSize = 1
)
