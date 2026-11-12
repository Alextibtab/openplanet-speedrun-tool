class CampaignListSWTab : SWTab
{
    Net::HttpRequest@ m_request;
    array<CampaignSummary@> campaigns;
    uint request = 50;
    uint pageSize = 50;
    bool moreavailable = true;
    uint clearCount = 0;
    uint64 retryAfter = 0;

    bool ShowLoadMore() { return true; }

    void GetRequestParams(dictionary@ params){}

    void Clear()
    {
        campaigns.RemoveRange(0, campaigns.Length);
        moreavailable = true;
        request = pageSize;
        clearCount++;
        retryAfter = 0;
    }

    void Load() override {
        if (moreavailable && campaigns.Length < request && Time::Now >= retryAfter) {
            uint clearsBefore = clearCount;
            uint countBefore = campaigns.Length;
            LoadCampaigns(pageSize, countBefore);
            moreavailable = (campaigns.Length % pageSize) == 0;

            // Load() runs every frame. A request that adds nothing (empty or failed
            // result) left moreavailable true, so it was re-sent in a tight loop.
            // Wait before retrying, unless the list was cleared while loading.
            if (clearsBefore == clearCount && campaigns.Length <= countBefore) {
                retryAfter = Time::Now + 5000;
            }
        }
    }

    void LoadCampaigns(int count, int offset){}

    void RenderHeader(){}

    void RenderReloadButton()
    {
        vec2 posOrig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x-40, posOrig.y));
        if (UI::Button(Icons::Refresh))
        {
            Clear();
        }
        UI::SetCursorPos(vec2(posOrig.x, posOrig.y+12));
        UI::NewLine();
    }

    void Render() override
    {
        RenderHeader();

        if (campaigns.Length == 0) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
        } else {
            RenderReloadButton();
            if (campaigns.Length == 0) {
                UI::Text("No campaigns found.");
                return;
            }

            UI::BeginChild("campaignList");
            if (UI::BeginTable("List", 2)) {
                UI::TableSetupScrollFreeze(0, 1);
                PushTabStyle();
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Select", UI::TableColumnFlags::WidthFixed, 80);
                UI::TableHeadersRow();
                PopTabStyle();

                UI::ListClipper clipper(campaigns.Length);
                while(clipper.Step()) {
                    for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                    {
                        UI::PushID("CampaignListLine"+i);
                        CampaignSummary@ campaign = campaigns[i];
                        IfaceRender::CampaignListLine(campaign);
                        UI::PopID();
                    }
                }
                UI::EndTable();
                if (ShowLoadMore() && moreavailable && UI::GreenButton("Load more")){
                    request += pageSize;
                }
            }
            UI::EndChild();
        }
    }

}