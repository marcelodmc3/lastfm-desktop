/***************************************************************************
*   Copyright 2005-2008 Last.fm Ltd.                                      *
*                                                                         *
*   This program is free software; you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation; either version 2 of the License, or     *
*   (at your option) any later version.                                   *
*                                                                         *
*   This program is distributed in the hope that it will be useful,       *
*   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
*   GNU General Public License for more details.                          *
*                                                                         *
*   You should have received a copy of the GNU General Public License     *
*   along with this program; if not, write to the                         *
*   Free Software Foundation, Inc.,                                       *
*   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.         *
***************************************************************************/

#ifndef FIREHOSE_DELEGATE_H
#define FIREHOSE_DELEGATE_H

#include <QAbstractItemDelegate>


enum
{
    TrackRole = Qt::UserRole
};


class FirehoseDelegate : public QAbstractItemDelegate
{
	static int& metric()
	{
		static int metric;
		return metric;
	}

	virtual void paint( QPainter*, const QStyleOptionViewItem&, const QModelIndex& ) const;
	virtual QSize sizeHint( const QStyleOptionViewItem&, const QModelIndex& ) const;
};

#endif