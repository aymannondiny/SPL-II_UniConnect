import 'package:flutter/material.dart';

class CampusFeature {
  const CampusFeature(
    this.title,
    this.description,
    this.icon,
    this.tag, {
    this.featured = false,
  });
  final String title;
  final String description;
  final IconData icon;
  final String tag;
  final bool featured;
}

const campusFeatures = [
  CampusFeature(
    'Discover',
    'Find students and alumni by skill, department, company or graduation year.',
    Icons.search,
    'Core',
    featured: true,
  ),
  CampusFeature(
    'Connections',
    'Manage requests and see everyone you are connected with.',
    Icons.people_outline,
    'Core',
  ),
  CampusFeature(
    'Messages',
    'Chat one-to-one with people you are connected to.',
    Icons.chat_bubble_outline,
    'Core',
  ),
  CampusFeature(
    'Clubs & events',
    'Follow club announcements, see upcoming events and discover your communities.',
    Icons.calendar_today_outlined,
    'Core',
    featured: true,
  ),
  CampusFeature(
    'Project finder',
    'Post a project or apply to join one that needs your skills.',
    Icons.layers_outlined,
    'Next',
  ),
  CampusFeature(
    'Career board',
    'Browse internships and jobs shared by alumni.',
    Icons.work_outline,
    'Next',
  ),
  CampusFeature(
    'Mentorship',
    'Book sessions with a mentor, or offer your time.',
    Icons.school_outlined,
    'Core',
    featured: true,
  ),
  CampusFeature(
    'Notifications',
    'Requests, replies and club updates in one place.',
    Icons.notifications_none,
    'Core',
  ),
  CampusFeature(
    'My profile',
    'Edit your skills, privacy and availability.',
    Icons.person_outline,
    'Core',
  ),
  CampusFeature(
    'Administration',
    'Manage academic catalog options and your administrator account.',
    Icons.shield_outlined,
    'Admin only',
  ),
];
