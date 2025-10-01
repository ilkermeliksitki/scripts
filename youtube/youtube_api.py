import requests
import json

def search_youtube(query):
    endpoint = "https://www.youtube.com/youtubei/v1/search"
    
    # the request payload as a json object
    payload = {
        "context": {
            "client": {
                "clientName": "WEB",
                "clientVersion": "2.20220506.00.00"
            }
        },
        "query": query,
    }
    
    response = requests.post(endpoint, json=payload)
    
    response_json = json.loads(response.content.decode())
    
    try:
        contents = response_json['contents'] \
                ['twoColumnSearchResultsRenderer'] \
                ['primaryContents'] \
                ['sectionListRenderer'] \
                ['contents'][0] \
                ['itemSectionRenderer'] \
                ['contents']
    except KeyError:
        return []
    
    videos = []
    for content_dict in contents:
        if 'showingResultsForRenderer' in content_dict.keys():
            continue

        if 'videoRenderer' in content_dict.keys():
            vr = content_dict['videoRenderer']
            video = {
                'video_id': vr.get('videoId', ''),
                'title': vr.get('title', {}).get('runs', [{}])[0].get('text', ''),
                'view_count': vr.get('viewCountText', {}).get('simpleText', ''),
                'length_text': vr.get('lengthText', {}).get('accessibility', {}).get('accessibilityData', {}).get('label', ''),
                'owner': vr.get('ownerText', {}).get('runs', [{}])[0].get('text', ''),
                'published_time': vr.get('publishedTimeText', {}).get('simpleText', ''),
            }
            videos.append(video)
    return videos


