//
//  Consent.swift
//  OCKSample
//
//  Created by Jai Shah on 31/03/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/*
 TOD: The informedConsentHTML property allows you to display HTML
 on an ResearchKit Survey. Modify the consent so it properly
 represents the usecase of your application.
 */

let informedConsentHTML = """
<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta name="viewport" content="width=400, user-scalable=no">
    <meta charset="utf-8" />
    <style type="text/css">
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            padding: 10px;
        }
        ul, p, h1, h3 {
            text-align: left;
        }
    </style>
</head>
<body>

<h1>NeuroMallea Informed Consent</h1>

<p>
NeuroMallea is a mental health application designed to help users practice Cognitive Behavioral Therapy (CBT) techniques such as thought tracking, mood monitoring, and guided exercises.
</p>

<h3>What You Will Do</h3>
<ul>
    <li>Log thoughts, emotions, and behavioral patterns.</li>
    <li>Complete CBT-based exercises such as reframing negative thoughts and breathing activities.</li>
    <li>Respond to optional surveys related to mood and mental well-being.</li>
    <li>Receive reminders and notifications to complete exercises.</li>
</ul>

<h3>Data Collection & Usage</h3>
<ul>
    <li>The app may collect self-reported mental health data (e.g., mood, thoughts, triggers).</li>
    <li>This data is used to provide insights, track progress, and improve your experience.</li>
    <li>Your data will not be shared with third parties without your consent.</li>
    <li>All reasonable measures are taken to keep your data secure.</li>
</ul>

<h3>Important Considerations</h3>
<ul>
    <li>NeuroMallea is not a substitute for professional medical or psychiatric care.</li>
    <li>If you are experiencing a mental health crisis, please contact a licensed professional or emergency services.</li>
    <li>You may stop using the app at any time.</li>
</ul>

<h3>Eligibility Requirements</h3>
<ul>
    <li>You must be 18 years or older.</li>
    <li>You must be able to read and understand English.</li>
    <li>You must be the primary user of this device.</li>
</ul>

<h3>Voluntary Participation</h3>
<p>
Your use of NeuroMallea is completely voluntary. You may stop using the app or withdraw your consent at any time without penalty.
</p>

<h3>Consent</h3>
<p>
By signing below, you acknowledge that:
</p>
<ul>
    <li>You have read and understood this consent form.</li>
    <li>You agree to use NeuroMallea under the terms described above.</li>
    <li>You understand how your data will be collected and used.</li>
</ul>

<p>Please sign using your finger below.</p>

<br>

</body>
</html>
"""
